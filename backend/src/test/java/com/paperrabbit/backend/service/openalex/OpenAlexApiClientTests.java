package com.paperrabbit.backend.service.openalex;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.net.URI;
import java.time.Duration;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import com.paperrabbit.backend.config.OpenAlexProperties;
import com.paperrabbit.backend.dto.PageResponse;
import com.paperrabbit.backend.dto.PaperSummaryDto;
import com.paperrabbit.backend.exception.PaperNotFoundException;
import com.paperrabbit.backend.service.SearchMode;

class OpenAlexApiClientTests {

	private MockRestServiceServer server;
	private OpenAlexApiClient client;

	@BeforeEach
	void setUp() {
		RestClient.Builder builder = RestClient.builder().baseUrl("https://api.openalex.org");
		server = MockRestServiceServer.bindTo(builder).build();
		OpenAlexProperties properties = new OpenAlexProperties(
				URI.create("https://api.openalex.org"),
				"",
				Duration.ofSeconds(1),
				Duration.ofSeconds(1),
				1,
				Duration.ZERO);
		client = new OpenAlexApiClient(builder.build(), properties, new OpenAlexPaperMapper());
	}

	@Test
	void searchesAndMapsAnOpenAlexPage() {
		server.expect(request -> {
			assertThat(request.getURI().getPath()).isEqualTo("/works");
			assertThat(request.getURI().getQuery()).contains("search=graph learning");
			assertThat(request.getURI().getQuery()).contains("per_page=2");
		}).andRespond(withSuccess("""
				{
				  "meta": {"count": 9, "page": 1, "per_page": 2},
				  "results": [{
				    "id": "https://openalex.org/W42",
				    "title": "Graph learning",
				    "authorships": [],
				    "cited_by_count": 7
				  }]
				}
				""", MediaType.APPLICATION_JSON));

		PageResponse<PaperSummaryDto> response = client.search(
				"graph learning", SearchMode.KEYWORD, 1, 2);

		assertThat(response.total()).isEqualTo(9);
		assertThat(response.hasNext()).isTrue();
		assertThat(response.items()).extracting(PaperSummaryDto::id).containsExactly("W42");
		server.verify();
	}

	@Test
	void mapsAMissingSingletonToPaperNotFound() {
		server.expect(request -> assertThat(request.getURI().getPath()).isEqualTo("/works/W999"))
				.andRespond(withStatus(HttpStatus.NOT_FOUND));

		assertThatThrownBy(() -> client.getPaper("W999"))
				.isInstanceOf(PaperNotFoundException.class)
				.hasMessageContaining("W999");
		server.verify();
	}
}
