package com.paperrabbit.backend.exception;

import jakarta.validation.ConstraintViolationException;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

	@ExceptionHandler({PaperNotFoundException.class, LibraryPaperNotFoundException.class})
	ProblemDetail handleNotFound(RuntimeException exception) {
		String code = exception instanceof LibraryPaperNotFoundException
				? "LIBRARY_PAPER_NOT_FOUND"
				: "PAPER_NOT_FOUND";
		return problem(HttpStatus.NOT_FOUND, "Paper not found", exception.getMessage(), code);
	}

	@ExceptionHandler({IllegalArgumentException.class, ConstraintViolationException.class})
	ProblemDetail handleBadRequest(RuntimeException exception) {
		return problem(HttpStatus.BAD_REQUEST, "Invalid request", exception.getMessage(), "INVALID_REQUEST");
	}

	@ExceptionHandler(UpstreamServiceException.class)
	ProblemDetail handleUpstream(UpstreamServiceException exception) {
		String code = exception.isRateLimited() ? "RESEARCH_API_RATE_LIMITED" : "RESEARCH_API_UNAVAILABLE";
		String title = exception.isRateLimited()
				? "Research data rate limit reached"
				: "Research data temporarily unavailable";
		return problem(HttpStatus.SERVICE_UNAVAILABLE, title, exception.getMessage(), code);
	}

	private ProblemDetail problem(HttpStatus status, String title, String detail, String code) {
		ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
		problem.setTitle(title);
		problem.setProperty("code", code);
		return problem;
	}
}
