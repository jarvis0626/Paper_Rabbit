package com.paperrabbit.backend.dto;

import java.util.List;

public record PaperDetailsDto(
		String id,
		String title,
		List<AuthorDto> authors,
		Integer year,
		String publicationDate,
		String venue,
		String type,
		int citationCount,
		String abstractText,
		String doi,
		String externalUrl,
		String pdfUrl,
		List<TopicDto> topics,
		boolean openAccess,
		int referenceCount,
		List<String> referencedWorkIds,
		List<String> relatedWorkIds,
		String dataSource) {

	public PaperDetailsDto {
		authors = authors == null ? List.of() : List.copyOf(authors);
		topics = topics == null ? List.of() : List.copyOf(topics);
		referencedWorkIds = referencedWorkIds == null ? List.of() : List.copyOf(referencedWorkIds);
		relatedWorkIds = relatedWorkIds == null ? List.of() : List.copyOf(relatedWorkIds);
	}

	public PaperSummaryDto toSummary() {
		String preview = abstractText;
		if (preview != null && preview.length() > 320) {
			preview = preview.substring(0, 317).stripTrailing() + "...";
		}
		return new PaperSummaryDto(id, title, authors, year, venue, citationCount, preview,
				doi, externalUrl, topics, openAccess);
	}
}
