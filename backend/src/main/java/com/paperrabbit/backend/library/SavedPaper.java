package com.paperrabbit.backend.library;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.Table;

@Entity
@Table(name = "saved_papers")
public class SavedPaper {

	@Id
	@GeneratedValue(strategy = GenerationType.UUID)
	private UUID id;

	@Column(name = "paper_id", nullable = false, unique = true, length = 32)
	private String paperId;

	@Column(nullable = false, length = 1000)
	private String title;

	@ElementCollection(fetch = FetchType.EAGER)
	@CollectionTable(name = "saved_paper_authors", joinColumns = @JoinColumn(name = "saved_paper_id"))
	@OrderColumn(name = "author_order")
	@Column(name = "author_name", nullable = false, length = 500)
	private List<String> authors = new ArrayList<>();

	@Column(name = "publication_year")
	private Integer year;

	@Column(length = 1000)
	private String venue;

	@Column(name = "citation_count", nullable = false)
	private int citationCount;

	@Column(name = "external_url", columnDefinition = "TEXT")
	private String externalUrl;

	@Enumerated(EnumType.STRING)
	@Column(name = "reading_status", nullable = false, length = 32)
	private ReadingStatus readingStatus;

	@Column(columnDefinition = "TEXT")
	private String notes;

	@ElementCollection(fetch = FetchType.EAGER)
	@CollectionTable(name = "saved_paper_tags", joinColumns = @JoinColumn(name = "saved_paper_id"))
	@Column(name = "tag", nullable = false, length = 80)
	private Set<String> tags = new LinkedHashSet<>();

	@Column(name = "saved_at", nullable = false)
	private Instant savedAt;

	@Column(name = "updated_at", nullable = false)
	private Instant updatedAt;

	protected SavedPaper() {
	}

	public SavedPaper(
			String paperId,
			String title,
			List<String> authors,
			Integer year,
			String venue,
			int citationCount,
			String externalUrl) {
		this.paperId = paperId;
		this.readingStatus = ReadingStatus.TO_READ;
		this.savedAt = Instant.now();
		this.updatedAt = this.savedAt;
		refreshMetadata(title, authors, year, venue, citationCount, externalUrl);
	}

	public void refreshMetadata(
			String title,
			List<String> authors,
			Integer year,
			String venue,
			int citationCount,
			String externalUrl) {
		this.title = title;
		this.authors.clear();
		this.authors.addAll(authors);
		this.year = year;
		this.venue = venue;
		this.citationCount = citationCount;
		this.externalUrl = externalUrl;
		this.updatedAt = Instant.now();
	}

	public void updateWorkflow(ReadingStatus status, String notes, Set<String> tags) {
		this.readingStatus = status;
		this.notes = notes;
		this.tags.clear();
		this.tags.addAll(tags);
		this.updatedAt = Instant.now();
	}

	public UUID getId() {
		return id;
	}

	public String getPaperId() {
		return paperId;
	}

	public String getTitle() {
		return title;
	}

	public List<String> getAuthors() {
		return List.copyOf(authors);
	}

	public Integer getYear() {
		return year;
	}

	public String getVenue() {
		return venue;
	}

	public int getCitationCount() {
		return citationCount;
	}

	public String getExternalUrl() {
		return externalUrl;
	}

	public ReadingStatus getReadingStatus() {
		return readingStatus;
	}

	public String getNotes() {
		return notes;
	}

	public Set<String> getTags() {
		return Set.copyOf(tags);
	}

	public Instant getSavedAt() {
		return savedAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}
}
