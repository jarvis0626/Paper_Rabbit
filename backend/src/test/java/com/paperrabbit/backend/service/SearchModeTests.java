package com.paperrabbit.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import org.junit.jupiter.api.Test;

class SearchModeTests {

	@Test
	void parsesModesWithoutCaseSensitivity() {
		assertThat(SearchMode.from("keyword")).isEqualTo(SearchMode.KEYWORD);
		assertThat(SearchMode.from("SEMANTIC")).isEqualTo(SearchMode.SEMANTIC);
	}

	@Test
	void rejectsUnknownModes() {
		assertThatIllegalArgumentException()
				.isThrownBy(() -> SearchMode.from("chatbot"))
				.withMessageContaining("keyword");
	}
}
