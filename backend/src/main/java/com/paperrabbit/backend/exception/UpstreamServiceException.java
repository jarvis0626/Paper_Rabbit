package com.paperrabbit.backend.exception;

public class UpstreamServiceException extends RuntimeException {

	private final boolean rateLimited;

	public UpstreamServiceException(String message, boolean rateLimited, Throwable cause) {
		super(message, cause);
		this.rateLimited = rateLimited;
	}

	public UpstreamServiceException(String message, boolean rateLimited) {
		this(message, rateLimited, null);
	}

	public boolean isRateLimited() {
		return rateLimited;
	}
}
