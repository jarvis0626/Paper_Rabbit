package com.paperrabbit.backend.service;

import java.util.Locale;

public enum SearchMode {
	KEYWORD("search"),
	SEMANTIC("search.semantic");

	private final String queryParameter;

	SearchMode(String queryParameter) {
		this.queryParameter = queryParameter;
	}

	public String queryParameter() {
		return queryParameter;
	}

	public static SearchMode from(String value) {
		if (value == null || value.isBlank()) {
			return KEYWORD;
		}
		try {
			return valueOf(value.trim().toUpperCase(Locale.ROOT));
		} catch (IllegalArgumentException exception) {
			throw new IllegalArgumentException("Search mode must be 'keyword' or 'semantic'.");
		}
	}
}
