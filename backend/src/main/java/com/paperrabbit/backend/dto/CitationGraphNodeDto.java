package com.paperrabbit.backend.dto;

import java.util.List;

public record CitationGraphNodeDto(
		String id,
		String title,
		List<AuthorDto> authors,
		Integer year,
		int citationCount,
		String kind) {

	public CitationGraphNodeDto {
		authors = authors == null ? List.of() : List.copyOf(authors);
	}

	public static CitationGraphNodeDto root(PaperDetailsDto paper) {
		return new CitationGraphNodeDto(paper.id(), paper.title(), paper.authors(), paper.year(),
				paper.citationCount(), "root");
	}

	public static CitationGraphNodeDto related(PaperSummaryDto paper, String kind) {
		return new CitationGraphNodeDto(paper.id(), paper.title(), paper.authors(), paper.year(),
				paper.citationCount(), kind);
	}
}
