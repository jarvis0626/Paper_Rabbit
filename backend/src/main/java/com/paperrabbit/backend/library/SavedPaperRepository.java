package com.paperrabbit.backend.library;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface SavedPaperRepository extends JpaRepository<SavedPaper, UUID> {

	Optional<SavedPaper> findByPaperId(String paperId);

	List<SavedPaper> findAllByOrderBySavedAtDesc();
}
