package com.paperrabbit.backend.graph;

import com.paperrabbit.backend.dto.CitationGraphDto;

@FunctionalInterface
public interface CitationGraphStore {

	void save(CitationGraphDto graph);
}
