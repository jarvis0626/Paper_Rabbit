package com.paperrabbit.backend.graph;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.neo4j.core.Neo4jClient;
import org.springframework.stereotype.Component;

import com.paperrabbit.backend.dto.CitationGraphDto;
import com.paperrabbit.backend.dto.CitationGraphEdgeDto;
import com.paperrabbit.backend.dto.CitationGraphNodeDto;

@Component
public class Neo4jCitationGraphStore implements CitationGraphStore {

	private static final String CREATE_ID_CONSTRAINT = """
			CREATE CONSTRAINT paper_openalex_id IF NOT EXISTS
			FOR (paper:Paper) REQUIRE paper.id IS UNIQUE
			""";
	private static final String UPSERT_GRAPH = """
			UNWIND $nodes AS node
			MERGE (paper:Paper {id: node.id})
			SET paper.title = node.title,
			    paper.authors = node.authors,
			    paper.year = node.year,
			    paper.citationCount = node.citationCount,
			    paper.lastDiscoveredAt = $discoveredAt
			WITH count(paper) AS storedNodes
			UNWIND $edges AS edge
			MATCH (source:Paper {id: edge.sourceId})
			MATCH (target:Paper {id: edge.targetId})
			MERGE (source)-[citation:CITES]->(target)
			SET citation.lastDiscoveredAt = $discoveredAt
			RETURN storedNodes, count(citation) AS storedEdges
			""";

	private final Neo4jClient neo4jClient;
	private final boolean enabled;
	private volatile boolean constraintCreated;

	public Neo4jCitationGraphStore(
			Neo4jClient neo4jClient,
			@Value("${paper-rabbit.graph.persistence-enabled:false}") boolean enabled) {
		this.neo4jClient = neo4jClient;
		this.enabled = enabled;
	}

	@Override
	public void save(CitationGraphDto graph) {
		if (!enabled) {
			return;
		}
		ensureConstraint();
		neo4jClient.query(UPSERT_GRAPH)
				.bind(toNodes(graph.nodes())).to("nodes")
				.bind(toEdges(graph.edges())).to("edges")
				.bind(Instant.now().toString()).to("discoveredAt")
				.run();
	}

	private synchronized void ensureConstraint() {
		if (!constraintCreated) {
			neo4jClient.query(CREATE_ID_CONSTRAINT).run();
			constraintCreated = true;
		}
	}

	private List<Map<String, Object>> toNodes(List<CitationGraphNodeDto> nodes) {
		List<Map<String, Object>> values = new ArrayList<>();
		for (CitationGraphNodeDto node : nodes) {
			Map<String, Object> value = new HashMap<>();
			value.put("id", node.id());
			value.put("title", node.title());
			value.put("authors", node.authors().stream().map(author -> author.name()).toList());
			value.put("year", node.year());
			value.put("citationCount", node.citationCount());
			values.add(value);
		}
		return List.copyOf(values);
	}

	private List<Map<String, Object>> toEdges(List<CitationGraphEdgeDto> edges) {
		return edges.stream()
				.map(edge -> Map.<String, Object>of(
						"sourceId", edge.sourceId(),
						"targetId", edge.targetId()))
				.toList();
	}
}
