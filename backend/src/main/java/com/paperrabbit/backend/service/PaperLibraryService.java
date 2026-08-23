package com.paperrabbit.backend.service;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.paperrabbit.backend.dto.LibraryPaperDto;
import com.paperrabbit.backend.dto.SavePaperRequest;
import com.paperrabbit.backend.dto.UpdateLibraryPaperRequest;
import com.paperrabbit.backend.exception.LibraryPaperNotFoundException;
import com.paperrabbit.backend.library.ReadingStatus;
import com.paperrabbit.backend.library.SavedPaper;
import com.paperrabbit.backend.library.SavedPaperRepository;

@Service
public class PaperLibraryService {

	private final SavedPaperRepository repository;

	public PaperLibraryService(SavedPaperRepository repository) {
		this.repository = repository;
	}

	@Transactional(readOnly = true)
	public List<LibraryPaperDto> list(ReadingStatus status, String tag, String query) {
		String normalizedTag = normalizeOptional(tag);
		String normalizedQuery = normalizeOptional(query);
		return repository.findAllByOrderBySavedAtDesc().stream()
				.filter(paper -> status == null || paper.getReadingStatus() == status)
				.filter(paper -> normalizedTag == null || paper.getTags().contains(normalizedTag))
				.filter(paper -> matchesQuery(paper, normalizedQuery))
				.map(LibraryPaperDto::from)
				.toList();
	}

	@Transactional(readOnly = true)
	public LibraryPaperDto get(String paperId) {
		return LibraryPaperDto.from(find(paperId));
	}

	@Transactional
	public LibraryPaperDto save(SavePaperRequest request) {
		String paperId = request.paperId().strip().toUpperCase(Locale.ROOT);
		SavedPaper paper = repository.findByPaperId(paperId)
				.orElseGet(() -> new SavedPaper(paperId, request.title().strip(), cleanAuthors(request.authors()),
						request.year(), cleanOptional(request.venue()), request.citationCount(),
						cleanOptional(request.externalUrl())));
		paper.refreshMetadata(request.title().strip(), cleanAuthors(request.authors()), request.year(),
				cleanOptional(request.venue()), request.citationCount(), cleanOptional(request.externalUrl()));
		return LibraryPaperDto.from(repository.save(paper));
	}

	@Transactional
	public LibraryPaperDto update(String paperId, UpdateLibraryPaperRequest request) {
		SavedPaper paper = find(paperId);
		paper.updateWorkflow(request.readingStatus(), cleanOptional(request.notes()), cleanTags(request.tags()));
		return LibraryPaperDto.from(repository.save(paper));
	}

	@Transactional
	public void delete(String paperId) {
		repository.delete(find(paperId));
	}

	private SavedPaper find(String paperId) {
		String normalized = paperId == null ? "" : paperId.strip().toUpperCase(Locale.ROOT);
		return repository.findByPaperId(normalized)
				.orElseThrow(() -> new LibraryPaperNotFoundException(normalized));
	}

	private boolean matchesQuery(SavedPaper paper, String query) {
		if (query == null) {
			return true;
		}
		return paper.getTitle().toLowerCase(Locale.ROOT).contains(query)
				|| paper.getAuthors().stream()
						.anyMatch(author -> author.toLowerCase(Locale.ROOT).contains(query));
	}

	private List<String> cleanAuthors(List<String> authors) {
		return authors.stream().map(String::strip).filter(value -> !value.isEmpty()).toList();
	}

	private Set<String> cleanTags(Set<String> tags) {
		Set<String> cleaned = new LinkedHashSet<>();
		for (String tag : tags) {
			String value = normalizeOptional(tag);
			if (value != null) {
				cleaned.add(value);
			}
		}
		return Set.copyOf(cleaned);
	}

	private String normalizeOptional(String value) {
		String cleaned = cleanOptional(value);
		return cleaned == null ? null : cleaned.toLowerCase(Locale.ROOT);
	}

	private String cleanOptional(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}
		return value.strip();
	}
}
