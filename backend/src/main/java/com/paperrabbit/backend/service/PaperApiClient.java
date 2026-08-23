package com.paperrabbit.backend.service;

import java.util.List;

import com.paperrabbit.backend.dto.PageResponse;
import com.paperrabbit.backend.dto.PaperDetailsDto;
import com.paperrabbit.backend.dto.PaperSummaryDto;

public interface PaperApiClient {

	PageResponse<PaperSummaryDto> search(String query, SearchMode mode, int page, int pageSize);

	PaperDetailsDto getPaper(String paperId);

	List<PaperSummaryDto> getRelatedPapers(String paperId, int limit);

	PageResponse<PaperSummaryDto> getReferences(String paperId, int page, int pageSize);

	PageResponse<PaperSummaryDto> getCitations(String paperId, int page, int pageSize);
}
