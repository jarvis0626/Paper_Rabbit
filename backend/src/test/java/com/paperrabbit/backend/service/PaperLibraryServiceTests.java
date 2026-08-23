package com.paperrabbit.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import com.paperrabbit.backend.dto.LibraryPaperDto;
import com.paperrabbit.backend.dto.SavePaperRequest;
import com.paperrabbit.backend.dto.UpdateLibraryPaperRequest;
import com.paperrabbit.backend.exception.LibraryPaperNotFoundException;
import com.paperrabbit.backend.library.ReadingStatus;
import com.paperrabbit.backend.library.SavedPaperRepository;

@DataJpaTest
@ActiveProfiles("test")
class PaperLibraryServiceTests {

	@Autowired
	private SavedPaperRepository repository;

	private PaperLibraryService service;

	@BeforeEach
	void setUp() {
		service = new PaperLibraryService(repository);
	}

	@Test
	void savesUpdatesFiltersAndDeletesPaper() {
		LibraryPaperDto saved = service.save(new SavePaperRequest(
				"w123", "Graph Research", List.of("Ada Author"), 2025, "Test Journal",
				12, "https://example.org/paper"));

		assertThat(saved.paperId()).isEqualTo("W123");
		assertThat(saved.readingStatus()).isEqualTo(ReadingStatus.TO_READ);

		LibraryPaperDto updated = service.update("W123", new UpdateLibraryPaperRequest(
				ReadingStatus.READING, "Strong methods section", Set.of("AI", " Priority ")));

		assertThat(updated.tags()).containsExactlyInAnyOrder("ai", "priority");
		assertThat(service.list(ReadingStatus.READING, "AI", "ada")).hasSize(1);
		assertThat(service.list(ReadingStatus.READ, null, null)).isEmpty();

		service.delete("w123");
		assertThatThrownBy(() -> service.get("W123"))
				.isInstanceOf(LibraryPaperNotFoundException.class);
	}

	@Test
	void savingAgainRefreshesMetadataWithoutDuplicatingWorkflow() {
		SavePaperRequest first = new SavePaperRequest(
				"W5", "First title", List.of(), 2024, null, 1, null);
		service.save(first);
		service.update("W5", new UpdateLibraryPaperRequest(
				ReadingStatus.READ, "Finished", Set.of("favorite")));

		LibraryPaperDto refreshed = service.save(new SavePaperRequest(
				"W5", "Corrected title", List.of("New Author"), 2025, null, 2, null));

		assertThat(repository.count()).isEqualTo(1);
		assertThat(refreshed.title()).isEqualTo("Corrected title");
		assertThat(refreshed.readingStatus()).isEqualTo(ReadingStatus.READ);
		assertThat(refreshed.notes()).isEqualTo("Finished");
		assertThat(refreshed.tags()).containsExactly("favorite");
	}
}
