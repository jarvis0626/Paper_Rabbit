package com.paperrabbit.backend.exception;

public class PaperNotFoundException extends RuntimeException {

	public PaperNotFoundException(String paperId) {
		super("No paper was found for OpenAlex ID " + paperId + ".");
	}
}
