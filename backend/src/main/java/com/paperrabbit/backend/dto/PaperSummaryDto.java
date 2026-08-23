package com.paperrabbit.backend.dto;

import java.util.List;

public record PaperSummaryDto(
		String id,
		String title,
		List<AuthorDto> authors,
		Integer year,
		String venue,
		int citationCount,
		String abstractPreview,
		String doi,
		String externalUrl,
		List<TopicDto> topics,
		boolean openAccess) {

	public PaperSummaryDto {
		authors = authors == null ? List.of() : List.copyOf(authors);
		topics = topics == null ? List.of() : List.copyOf(topics);
	}
}
