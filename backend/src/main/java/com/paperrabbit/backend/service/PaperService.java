package com.paperrabbit.backend.service;

import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

import org.springframework.stereotype.Service;

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

	private String normalizePaperId(String paperId) {
		String normalized = paperId == null ? "" : paperId.strip().toUpperCase(Locale.ROOT);
		if (!OPENALEX_WORK_ID.matcher(normalized).matches()) {
			throw new IllegalArgumentException("Paper ID must be a valid OpenAlex work ID such as W2741809807.");
		}
		return normalized;
	}
}
