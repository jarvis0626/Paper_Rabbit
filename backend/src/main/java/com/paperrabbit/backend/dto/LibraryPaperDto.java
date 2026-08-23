package com.paperrabbit.backend.dto;

import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import com.paperrabbit.backend.library.ReadingStatus;
import com.paperrabbit.backend.library.SavedPaper;

public record LibraryPaperDto(
		UUID id,
		String paperId,
		String title,
		List<String> authors,
		Integer year,
		String venue,
		int citationCount,
		String externalUrl,
		ReadingStatus readingStatus,
		String notes,
		Set<String> tags,
		Instant savedAt,
		Instant updatedAt) {

	public static LibraryPaperDto from(SavedPaper paper) {
		return new LibraryPaperDto(paper.getId(), paper.getPaperId(), paper.getTitle(),
				paper.getAuthors(), paper.getYear(), paper.getVenue(), paper.getCitationCount(),
				paper.getExternalUrl(), paper.getReadingStatus(), paper.getNotes(), paper.getTags(),
				paper.getSavedAt(), paper.getUpdatedAt());
	}
}
