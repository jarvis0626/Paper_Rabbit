package com.paperrabbit.backend.service.openalex;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import org.springframework.stereotype.Component;

import com.paperrabbit.backend.dto.AuthorDto;
import com.paperrabbit.backend.dto.PaperDetailsDto;
import com.paperrabbit.backend.dto.PaperSummaryDto;
import com.paperrabbit.backend.dto.TopicDto;
import com.paperrabbit.backend.exception.UpstreamServiceException;

import tools.jackson.databind.JsonNode;

@Component
public class OpenAlexPaperMapper {

	private static final int MAX_ABSTRACT_TOKENS = 50_000;

	public PaperDetailsDto toDetails(JsonNode work) {
		if (work == null || !work.isObject()) {
			throw new UpstreamServiceException("OpenAlex returned an invalid paper record.", false);
		}

		String id = normalizeId(text(work, "id"));
		if (id == null) {
			throw new UpstreamServiceException("OpenAlex returned a paper without a valid ID.", false);
		}

		String title = firstText(work, "title", "display_name");
		if (title == null) {
			title = "Untitled paper";
		}
		String abstractText = reconstructAbstract(work.get("abstract_inverted_index"));
		String doi = text(work, "doi");
		String landingPage = nestedText(work, "primary_location", "landing_page_url");
		String externalUrl = firstNonBlank(landingPage, doi, "https://openalex.org/" + id);
		String pdfUrl = nestedText(work, "best_oa_location", "pdf_url");
		String venue = nestedText(work, "primary_location", "source", "display_name");
		boolean openAccess = work.path("open_access").path("is_oa").asBoolean(false);

		List<String> referencedIds = idList(work.get("referenced_works"));
		List<String> relatedIds = idList(work.get("related_works"));
		int referenceCount = work.path("referenced_works_count").asInt(referencedIds.size());

		return new PaperDetailsDto(
				id,
				title,
				authors(work.get("authorships")),
				nullableInt(work.get("publication_year")),
				text(work, "publication_date"),
				venue,
				text(work, "type"),
				work.path("cited_by_count").asInt(0),
				abstractText,
				doi,
				externalUrl,
				pdfUrl,
				topics(work.get("topics")),
				openAccess,
				referenceCount,
				referencedIds,
				relatedIds,
				"OpenAlex");
	}

	public PaperSummaryDto toSummary(JsonNode work) {
		return toDetails(work).toSummary();
	}

	private List<AuthorDto> authors(JsonNode authorships) {
		if (authorships == null || !authorships.isArray()) {
			return List.of();
		}
		Map<String, AuthorDto> authors = new LinkedHashMap<>();
		for (JsonNode authorship : authorships) {
			JsonNode author = authorship.path("author");
			String name = text(author, "display_name");
			if (name == null) {
				name = text(authorship, "raw_author_name");
			}
			if (name == null) {
				continue;
			}
			String id = normalizeId(text(author, "id"));
			String key = id == null ? name : id;
			authors.putIfAbsent(key, new AuthorDto(id, name));
		}
		return List.copyOf(authors.values());
	}

	private List<TopicDto> topics(JsonNode topicNodes) {
		if (topicNodes == null || !topicNodes.isArray()) {
			return List.of();
		}
		List<TopicDto> topics = new ArrayList<>();
		for (JsonNode topic : topicNodes) {
			String name = text(topic, "display_name");
			if (name == null) {
				continue;
			}
			topics.add(new TopicDto(
					normalizeId(text(topic, "id")),
					name,
					topic.path("score").asDouble(0),
					nestedText(topic, "field", "display_name"),
					nestedText(topic, "subfield", "display_name")));
		}
		return List.copyOf(topics);
	}

	private List<String> idList(JsonNode nodes) {
		if (nodes == null || !nodes.isArray()) {
			return List.of();
		}
		List<String> ids = new ArrayList<>();
		for (JsonNode node : nodes) {
			String id = normalizeId(node.asString(null));
			if (id != null && id.startsWith("W")) {
				ids.add(id);
			}
		}
		return List.copyOf(ids);
	}

	private String reconstructAbstract(JsonNode invertedIndex) {
		if (invertedIndex == null || !invertedIndex.isObject()) {
			return null;
		}
		Map<Integer, String> wordsByPosition = new TreeMap<>();
		invertedIndex.properties().forEach(entry -> {
			if (!entry.getValue().isArray()) {
				return;
			}
			for (JsonNode position : entry.getValue()) {
				if (position.canConvertToInt()) {
					int index = position.asInt();
					if (index >= 0 && index < MAX_ABSTRACT_TOKENS) {
						wordsByPosition.putIfAbsent(index, entry.getKey());
					}
				}
			}
		});
		if (wordsByPosition.isEmpty()) {
			return null;
		}
		return String.join(" ", wordsByPosition.values())
				.replaceAll("\\s+([,.;:!?%)])", "$1")
				.replaceAll("([(])\\s+", "$1");
	}

	private Integer nullableInt(JsonNode node) {
		return node != null && node.canConvertToInt() ? node.asInt() : null;
	}

	private String firstText(JsonNode node, String... fields) {
		for (String field : fields) {
			String value = text(node, field);
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	private String nestedText(JsonNode node, String... path) {
		JsonNode current = node;
		for (String segment : path) {
			if (current == null || current.isMissingNode() || current.isNull()) {
				return null;
			}
			current = current.get(segment);
		}
		return cleanText(current);
	}

	private String text(JsonNode node, String field) {
		return node == null ? null : cleanText(node.get(field));
	}

	private String cleanText(JsonNode node) {
		if (node == null || !node.isString()) {
			return null;
		}
		String value = node.asString().strip();
		return value.isEmpty() ? null : value;
	}

	private String firstNonBlank(String... values) {
		for (String value : values) {
			if (value != null && !value.isBlank()) {
				return value;
			}
		}
		return null;
	}

	String normalizeId(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}
		int slash = value.lastIndexOf('/');
		return (slash >= 0 ? value.substring(slash + 1) : value).toUpperCase();
	}
}
