package com.paperrabbit.backend.service.openalex;

import java.net.URI;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.util.UriComponentsBuilder;

import com.paperrabbit.backend.config.OpenAlexProperties;
import com.paperrabbit.backend.dto.PageResponse;
import com.paperrabbit.backend.dto.PaperDetailsDto;
import com.paperrabbit.backend.dto.PaperSummaryDto;
import com.paperrabbit.backend.exception.PaperNotFoundException;
import com.paperrabbit.backend.exception.UpstreamServiceException;
import com.paperrabbit.backend.service.PaperApiClient;
import com.paperrabbit.backend.service.SearchMode;

import tools.jackson.databind.JsonNode;

@Component
public class OpenAlexApiClient implements PaperApiClient {

	private static final Logger log = LoggerFactory.getLogger(OpenAlexApiClient.class);
	private static final String SUMMARY_FIELDS = String.join(",",
			"id", "title", "authorships", "publication_year", "primary_location",
			"cited_by_count", "abstract_inverted_index", "doi", "open_access",
			"best_oa_location", "topics", "type");
	private static final String DETAIL_FIELDS = SUMMARY_FIELDS
			+ ",publication_date,referenced_works,referenced_works_count,related_works";

	private final RestClient restClient;
	private final OpenAlexProperties properties;
	private final OpenAlexPaperMapper mapper;

	public OpenAlexApiClient(
			RestClient openAlexRestClient,
			OpenAlexProperties properties,
			OpenAlexPaperMapper mapper) {
		this.restClient = openAlexRestClient;
		this.properties = properties;
		this.mapper = mapper;
	}

	@Override
	public PageResponse<PaperSummaryDto> search(
			String query, SearchMode mode, int page, int pageSize) {
		URI uri = UriComponentsBuilder.fromPath("/works")
				.queryParam(mode.queryParameter(), query)
				.queryParam("page", page)
				.queryParam("per_page", pageSize)
				.queryParam("select", SUMMARY_FIELDS)
				.build()
				.encode()
				.toUri();
		return mapPage(get(uri, null), page, pageSize);
	}

	@Override
	public PaperDetailsDto getPaper(String paperId) {
		URI uri = UriComponentsBuilder.fromPath("/works/{paperId}")
				.queryParam("select", DETAIL_FIELDS)
				.buildAndExpand(paperId)
				.encode()
				.toUri();
		return mapper.toDetails(get(uri, paperId));
	}

	@Override
	public List<PaperSummaryDto> getRelatedPapers(String paperId, int limit) {
		PaperDetailsDto paper = getPaper(paperId);
		List<String> ids = paper.relatedWorkIds().stream().limit(limit).toList();
		return batchFetch(ids);
	}

	@Override
	public PageResponse<PaperSummaryDto> getReferences(String paperId, int page, int pageSize) {
		PaperDetailsDto paper = getPaper(paperId);
		List<String> ids = paper.referencedWorkIds();
		int fromIndex = Math.min((page - 1) * pageSize, ids.size());
		int toIndex = Math.min(fromIndex + pageSize, ids.size());
		List<PaperSummaryDto> references = batchFetch(ids.subList(fromIndex, toIndex));
		return new PageResponse<>(references, page, pageSize, ids.size(), toIndex < ids.size());
	}

	@Override
	public PageResponse<PaperSummaryDto> getCitations(String paperId, int page, int pageSize) {
		URI uri = UriComponentsBuilder.fromPath("/works")
				.queryParam("filter", "cites:" + paperId)
				.queryParam("sort", "cited_by_count:desc")
				.queryParam("page", page)
				.queryParam("per_page", pageSize)
				.queryParam("select", SUMMARY_FIELDS)
				.build()
				.encode()
				.toUri();
		return mapPage(get(uri, null), page, pageSize);
	}

	private List<PaperSummaryDto> batchFetch(List<String> ids) {
		if (ids.isEmpty()) {
			return List.of();
		}
		URI uri = UriComponentsBuilder.fromPath("/works")
				.queryParam("filter", "openalex:" + String.join("|", ids))
				.queryParam("per_page", Math.min(ids.size(), 100))
				.queryParam("select", SUMMARY_FIELDS)
				.build()
				.encode()
				.toUri();
		JsonNode response = get(uri, null);
		JsonNode results = requireResults(response);
		Map<String, PaperSummaryDto> papersById = new HashMap<>();
		for (JsonNode result : results) {
			PaperSummaryDto summary = mapper.toSummary(result);
			papersById.put(summary.id(), summary);
		}
		List<PaperSummaryDto> ordered = new ArrayList<>();
		for (String id : ids) {
			PaperSummaryDto paper = papersById.get(id);
			if (paper != null) {
				ordered.add(paper);
			}
		}
		return List.copyOf(ordered);
	}

	private PageResponse<PaperSummaryDto> mapPage(JsonNode response, int page, int pageSize) {
		JsonNode results = requireResults(response);
		List<PaperSummaryDto> items = new ArrayList<>();
		for (JsonNode result : results) {
			items.add(mapper.toSummary(result));
		}
		long total = response.path("meta").path("count").asLong(items.size());
		boolean hasNext = (long) page * pageSize < total;
		return new PageResponse<>(items, page, pageSize, total, hasNext);
	}

	private JsonNode requireResults(JsonNode response) {
		JsonNode results = response == null ? null : response.get("results");
		if (results == null || !results.isArray()) {
			throw new UpstreamServiceException("OpenAlex returned an invalid results page.", false);
		}
		return results;
	}

	private JsonNode get(URI uri, String paperId) {
		RestClientResponseException lastResponseException = null;
		for (int attempt = 1; attempt <= properties.maxAttempts(); attempt++) {
			try {
				JsonNode response = restClient.get().uri(uri).retrieve().body(JsonNode.class);
				if (response == null) {
					throw new UpstreamServiceException("OpenAlex returned an empty response.", false);
				}
				return response;
			} catch (RestClientResponseException exception) {
				lastResponseException = exception;
				HttpStatusCode status = exception.getStatusCode();
				if (status.value() == 404 && paperId != null) {
					throw new PaperNotFoundException(paperId);
				}
				boolean retryable = status.value() == 429 || status.is5xxServerError();
				if (!retryable || attempt == properties.maxAttempts()) {
					boolean rateLimited = status.value() == 429;
					throw new UpstreamServiceException(
							rateLimited
									? "OpenAlex is rate limiting requests. Please try again shortly."
									: "OpenAlex could not complete the research data request.",
							rateLimited,
							exception);
				}
				log.warn("OpenAlex request failed with status {} (attempt {}/{}).",
						status.value(), attempt, properties.maxAttempts());
				backoff(attempt);
			} catch (ResourceAccessException exception) {
				if (attempt == properties.maxAttempts()) {
					throw new UpstreamServiceException(
							"OpenAlex did not respond in time. Please try again.", false, exception);
				}
				log.warn("OpenAlex connection failed (attempt {}/{}).", attempt, properties.maxAttempts());
				backoff(attempt);
			}
		}
		throw new UpstreamServiceException("OpenAlex is temporarily unavailable.", false, lastResponseException);
	}

	private void backoff(int attempt) {
		Duration delay = properties.initialBackoff().multipliedBy(1L << Math.min(attempt - 1, 10));
		try {
			Thread.sleep(delay.toMillis());
		} catch (InterruptedException exception) {
			Thread.currentThread().interrupt();
			throw new UpstreamServiceException("The OpenAlex request was interrupted.", false, exception);
		}
	}
}
