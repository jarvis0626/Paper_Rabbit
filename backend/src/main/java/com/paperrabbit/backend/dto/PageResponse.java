package com.paperrabbit.backend.dto;

import java.util.List;

public record PageResponse<T>(
		List<T> items,
		int page,
		int pageSize,
		long total,
		boolean hasNext) {

	public PageResponse {
		items = items == null ? List.of() : List.copyOf(items);
	}
}
