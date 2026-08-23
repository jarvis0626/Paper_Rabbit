package com.paperrabbit.backend.exception;

public class LibraryPaperNotFoundException extends RuntimeException {

	public LibraryPaperNotFoundException(String paperId) {
		super("Paper " + paperId + " is not saved in the library.");
	}
}
