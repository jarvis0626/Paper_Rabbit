package com.paperrabbit.backend.dto;

import java.util.List;

public record CitationGraphDto(
		String rootId,
		List<CitationGraphNodeDto> nodes,
		List<CitationGraphEdgeDto> edges,
		boolean truncated) {

	public CitationGraphDto {
		nodes = nodes == null ? List.of() : List.copyOf(nodes);
		edges = edges == null ? List.of() : List.copyOf(edges);
	}
}
