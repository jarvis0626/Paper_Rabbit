package com.paperrabbit.backend.service.openalex;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

import com.paperrabbit.backend.dto.PaperDetailsDto;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

class OpenAlexPaperMapperTests {

	private final JsonMapper objectMapper = JsonMapper.builder().build();
	private final OpenAlexPaperMapper mapper = new OpenAlexPaperMapper();

	@Test
	void mapsAWorkAndReconstructsItsAbstract() throws Exception {
		JsonNode work = objectMapper.readTree("""
				{
				  "id": "https://openalex.org/W123",
				  "title": "A useful paper",
				  "publication_year": 2025,
				  "publication_date": "2025-04-12",
				  "type": "article",
				  "doi": "https://doi.org/10.1000/example",
				  "cited_by_count": 42,
				  "abstract_inverted_index": {
				    "Paper": [0], "Rabbit": [1], "works": [2], ".": [3]
				  },
				  "authorships": [
				    {"author": {"id": "https://openalex.org/A1", "display_name": "Ada Researcher"}}
				  ],
				  "primary_location": {
				    "landing_page_url": "https://example.org/paper",
				    "source": {"display_name": "Journal of Useful Research"}
				  },
				  "best_oa_location": {"pdf_url": "https://example.org/paper.pdf"},
				  "open_access": {"is_oa": true},
				  "topics": [{
				    "id": "https://openalex.org/T1",
				    "display_name": "Research Discovery",
				    "score": 0.91,
				    "field": {"display_name": "Computer Science"},
				    "subfield": {"display_name": "Information Systems"}
				  }],
				  "referenced_works": ["https://openalex.org/W2"],
				  "referenced_works_count": 1,
				  "related_works": ["https://openalex.org/W3"]
				}
				""");

		PaperDetailsDto paper = mapper.toDetails(work);

		assertThat(paper.id()).isEqualTo("W123");
		assertThat(paper.title()).isEqualTo("A useful paper");
		assertThat(paper.abstractText()).isEqualTo("Paper Rabbit works.");
		assertThat(paper.authors()).extracting("name").containsExactly("Ada Researcher");
		assertThat(paper.venue()).isEqualTo("Journal of Useful Research");
		assertThat(paper.topics()).extracting("name").containsExactly("Research Discovery");
		assertThat(paper.referencedWorkIds()).containsExactly("W2");
		assertThat(paper.relatedWorkIds()).containsExactly("W3");
		assertThat(paper.openAccess()).isTrue();
	}

	@Test
	void toleratesMissingOptionalMetadata() throws Exception {
		JsonNode work = objectMapper.readTree("""
				{"id":"https://openalex.org/W9","display_name":"Sparse metadata"}
				""");

		PaperDetailsDto paper = mapper.toDetails(work);

		assertThat(paper.id()).isEqualTo("W9");
		assertThat(paper.authors()).isEmpty();
		assertThat(paper.topics()).isEmpty();
		assertThat(paper.abstractText()).isNull();
		assertThat(paper.externalUrl()).isEqualTo("https://openalex.org/W9");
	}
}
