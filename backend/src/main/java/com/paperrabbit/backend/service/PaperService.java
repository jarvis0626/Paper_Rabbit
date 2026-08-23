package com.paperrabbit.backend.service;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

import com.paperrabbit.backend.dto.CitationGraphDto;
import com.paperrabbit.backend.dto.CitationGraphEdgeDto;
import com.paperrabbit.backend.dto.CitationGraphNodeDto;
import com.paperrabbit.backend.dto.PageResponse;
import com.paperrabbit.backend.dto.PaperDetailsDto;
import com.paperrabbit.backend.dto.PaperSummaryDto;

@Service
public class PaperService {

	private static final Pattern OPENALEX_WORK_ID = Pattern.compile("W\\d{1,20}");

	private final PaperApiClient paperApiClient;

	public PaperService(PaperApiClient paperApiClient) {
		this.paperApiClient = paperApiClient;
	}

	public PageResponse<PaperSummaryDto> search(
			String query, String mode, int page, int pageSize) {
		return paperApiClient.search(query.strip(), SearchMode.from(mode), page, pageSize);
	}

	public PaperDetailsDto getPaper(String paperId) {
		return paperApiClient.getPaper(normalizePaperId(paperId));
	}

	public List<PaperSummaryDto> getRelatedPapers(String paperId, int limit) {
		return paperApiClient.getRelatedPapers(normalizePaperId(paperId), limit);
	}

	public PageResponse<PaperSummaryDto> getReferences(String paperId, int page, int pageSize) {
		return paperApiClient.getReferences(normalizePaperId(paperId), page, pageSize);
	}

	public PageResponse<PaperSummaryDto> getCitations(String paperId, int page, int pageSize) {
		return paperApiClient.getCitations(normalizePaperId(paperId), page, pageSize);
	}

	public CitationGraphDto getCitationGraph(String paperId, int referenceLimit, int citationLimit) {
		String normalizedId = normalizePaperId(paperId);
		PaperDetailsDto root = paperApiClient.getPaper(normalizedId);
		List<String> referenceIds = root.referencedWorkIds().stream()
				.limit(referenceLimit)
				.toList();
		List<PaperSummaryDto> references = paperApiClient.getPapers(referenceIds);
		PageResponse<PaperSummaryDto> citations = paperApiClient.getCitations(
				normalizedId, 1, citationLimit);

		Map<String, CitationGraphNodeDto> nodes = new LinkedHashMap<>();
		Set<CitationGraphEdgeDto> edges = new LinkedHashSet<>();
		nodes.put(root.id(), CitationGraphNodeDto.root(root));

		for (PaperSummaryDto reference : references) {
			if (!reference.id().equals(root.id())) {
				nodes.putIfAbsent(reference.id(), CitationGraphNodeDto.related(reference, "reference"));
				edges.add(new CitationGraphEdgeDto(root.id(), reference.id(), "cites"));
			}
		}
		for (PaperSummaryDto citation : citations.items()) {
			if (!citation.id().equals(root.id())) {
				nodes.putIfAbsent(citation.id(), CitationGraphNodeDto.related(citation, "citation"));
				edges.add(new CitationGraphEdgeDto(citation.id(), root.id(), "cites"));
			}
		}

		return new CitationGraphDto(root.id(), List.copyOf(nodes.values()), List.copyOf(edges),
				root.referencedWorkIds().size() > referenceIds.size() || citations.hasNext());
	}

	private String normalizePaperId(String paperId) {
		String normalized = paperId == null ? "" : paperId.strip().toUpperCase(Locale.ROOT);
		if (!OPENALEX_WORK_ID.matcher(normalized).matches()) {
			throw new IllegalArgumentException("Paper ID must be a valid OpenAlex work ID such as W2741809807.");
		}
		return normalized;
	}
}
