package com.paperrabbit.backend.dto;

import java.util.Set;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import com.paperrabbit.backend.library.ReadingStatus;

public record UpdateLibraryPaperRequest(
		@NotNull ReadingStatus readingStatus,
		@Size(max = 20000) String notes,
		@Size(max = 20) Set<@Size(min = 1, max = 80) String> tags) {

	public UpdateLibraryPaperRequest {
		tags = tags == null ? Set.of() : Set.copyOf(tags);
	}
}
