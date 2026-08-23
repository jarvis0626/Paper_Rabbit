package com.paperrabbit.backend.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

import org.junit.jupiter.api.Test;

import com.paperrabbit.backend.dto.AuthorDto;
import com.paperrabbit.backend.dto.CitationGraphDto;
import com.paperrabbit.backend.dto.CitationGraphEdgeDto;
import com.paperrabbit.backend.dto.PageResponse;
import com.paperrabbit.backend.dto.PaperDetailsDto;
import com.paperrabbit.backend.dto.PaperSummaryDto;

class PaperServiceGraphTests {

	@Test
	void graphPreservesCitationDirectionAndDeduplicatesNodes() {
		AtomicReference<CitationGraphDto> stored = new AtomicReference<>();
		PaperService service = new PaperService(new GraphFixtureClient(), stored::set);

		CitationGraphDto graph = service.getCitationGraph("w100", 10, 10);

		assertThat(graph.rootId()).isEqualTo("W100");
		assertThat(graph.nodes()).extracting(node -> node.id())
				.containsExactly("W100", "W200", "W300");
		assertThat(graph.edges()).containsExactly(
				new CitationGraphEdgeDto("W100", "W200", "cites"),
				new CitationGraphEdgeDto("W200", "W100", "cites"),
				new CitationGraphEdgeDto("W300", "W100", "cites"));
		assertThat(graph.truncated()).isTrue();
		assertThat(stored.get()).isSameAs(graph);
	}

	@Test
	void graphRemainsAvailableWhenPersistenceFails() {
		PaperService service = new PaperService(new GraphFixtureClient(), graph -> {
			throw new IllegalStateException("Neo4j unavailable");
		});

		CitationGraphDto graph = service.getCitationGraph("W100", 10, 10);

		assertThat(graph.nodes()).hasSize(3);
	}

	private static class GraphFixtureClient implements PaperApiClient {

		private final PaperSummaryDto shared = summary("W200", "Shared paper");

		@Override
		public PageResponse<PaperSummaryDto> search(
				String query, SearchMode mode, int page, int pageSize) {
			throw new UnsupportedOperationException();
		}

		@Override
		public PaperDetailsDto getPaper(String paperId) {
			return new PaperDetailsDto("W100", "Root paper", List.of(new AuthorDto("A1", "Ada")),
					2025, "2025-01-01", "Test venue", "article", 20, "Abstract", null,
					null, null, List.of(), true, 1, List.of("W200"), List.of(), "OpenAlex");
		}

		@Override
		public List<PaperSummaryDto> getRelatedPapers(String paperId, int limit) {
			throw new UnsupportedOperationException();
		}

		@Override
		public List<PaperSummaryDto> getPapers(List<String> paperIds) {
			return List.of(shared);
		}

		@Override
		public PageResponse<PaperSummaryDto> getReferences(String paperId, int page, int pageSize) {
			return new PageResponse<>(List.of(shared), 1, pageSize, 1, false);
		}

		@Override
		public PageResponse<PaperSummaryDto> getCitations(String paperId, int page, int pageSize) {
			return new PageResponse<>(List.of(shared, summary("W300", "Citing paper")),
					1, pageSize, 40, true);
		}

		private static PaperSummaryDto summary(String id, String title) {
			return new PaperSummaryDto(id, title, List.of(), 2024, null, 3, null,
					null, null, List.of(), false);
		}
	}
}
