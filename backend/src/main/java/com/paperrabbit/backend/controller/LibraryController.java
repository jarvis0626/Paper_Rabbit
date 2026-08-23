package com.paperrabbit.backend.controller;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;

import org.springframework.http.HttpStatus;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.paperrabbit.backend.dto.LibraryPaperDto;
import com.paperrabbit.backend.dto.SavePaperRequest;
import com.paperrabbit.backend.dto.UpdateLibraryPaperRequest;
import com.paperrabbit.backend.library.ReadingStatus;
import com.paperrabbit.backend.service.PaperLibraryService;

@Validated
@RestController
@RequestMapping("/api/library")
public class LibraryController {

	private final PaperLibraryService libraryService;

	public LibraryController(PaperLibraryService libraryService) {
		this.libraryService = libraryService;
	}

	@GetMapping
	public List<LibraryPaperDto> list(
			@RequestParam(required = false) ReadingStatus status,
			@RequestParam(required = false) @Size(max = 80) String tag,
			@RequestParam(required = false) @Size(max = 500) String q) {
		return libraryService.list(status, tag, q);
	}

	@GetMapping("/{paperId}")
	public LibraryPaperDto get(@PathVariable String paperId) {
		return libraryService.get(paperId);
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public LibraryPaperDto save(@Valid @RequestBody SavePaperRequest request) {
		return libraryService.save(request);
	}

	@PutMapping("/{paperId}")
	public LibraryPaperDto update(
			@PathVariable String paperId,
			@Valid @RequestBody UpdateLibraryPaperRequest request) {
		return libraryService.update(paperId, request);
	}

	@DeleteMapping("/{paperId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void delete(@PathVariable String paperId) {
		libraryService.delete(paperId);
	}
}
