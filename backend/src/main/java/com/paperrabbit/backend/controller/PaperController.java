package com.paperrabbit.backend.controller;

import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.paperrabbit.backend.dto.PageResponse;
import com.paperrabbit.backend.dto.PaperDetailsDto;
import com.paperrabbit.backend.dto.PaperSummaryDto;
import com.paperrabbit.backend.service.PaperService;

@Validated
@RestController
@RequestMapping("/api/papers")
public class PaperController {

	private final PaperService paperService;

	public PaperController(PaperService paperService) {
		this.paperService = paperService;
	}

	@GetMapping("/search")
	public PageResponse<PaperSummaryDto> search(
			@RequestParam @NotBlank @Size(max = 500) String q,
			@RequestParam(defaultValue = "keyword") String mode,
			@RequestParam(defaultValue = "1") @Min(1) @Max(500) int page,
			@RequestParam(defaultValue = "20") @Min(1) @Max(50) int pageSize) {
		return paperService.search(q, mode, page, pageSize);
	}

	@GetMapping("/{paperId}")
	public PaperDetailsDto getPaper(@PathVariable String paperId) {
		return paperService.getPaper(paperId);
	}

	@GetMapping("/{paperId}/related")
	public List<PaperSummaryDto> getRelatedPapers(
			@PathVariable String paperId,
			@RequestParam(defaultValue = "10") @Min(1) @Max(50) int limit) {
		return paperService.getRelatedPapers(paperId, limit);
	}

	@GetMapping("/{paperId}/references")
	public PageResponse<PaperSummaryDto> getReferences(
			@PathVariable String paperId,
			@RequestParam(defaultValue = "1") @Min(1) @Max(500) int page,
			@RequestParam(defaultValue = "20") @Min(1) @Max(50) int pageSize) {
		return paperService.getReferences(paperId, page, pageSize);
	}

	@GetMapping("/{paperId}/citations")
	public PageResponse<PaperSummaryDto> getCitations(
			@PathVariable String paperId,
			@RequestParam(defaultValue = "1") @Min(1) @Max(500) int page,
			@RequestParam(defaultValue = "20") @Min(1) @Max(50) int pageSize) {
		return paperService.getCitations(paperId, page, pageSize);
	}
}
