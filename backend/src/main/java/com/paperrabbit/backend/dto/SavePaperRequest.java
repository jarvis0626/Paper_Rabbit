package com.paperrabbit.backend.dto;

import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record SavePaperRequest(
		@NotBlank @Pattern(regexp = "(?i)W\\d{1,20}") String paperId,
		@NotBlank @Size(max = 1000) String title,
		@NotNull @Size(max = 100) List<@NotBlank @Size(max = 500) String> authors,
		@Min(1000) @Max(3000) Integer year,
		@Size(max = 1000) String venue,
		@Min(0) int citationCount,
		@Size(max = 4000) String externalUrl) {

	public SavePaperRequest {
		authors = authors == null ? List.of() : List.copyOf(authors);
	}
}
