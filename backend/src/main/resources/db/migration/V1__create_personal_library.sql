CREATE TABLE saved_papers (
    id UUID PRIMARY KEY,
    paper_id VARCHAR(32) NOT NULL UNIQUE,
    title VARCHAR(1000) NOT NULL,
    publication_year INTEGER,
    venue VARCHAR(1000),
    citation_count INTEGER NOT NULL DEFAULT 0,
    external_url TEXT,
    reading_status VARCHAR(32) NOT NULL,
    notes TEXT,
    saved_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE saved_paper_authors (
    saved_paper_id UUID NOT NULL,
    author_name VARCHAR(500) NOT NULL,
    author_order INTEGER NOT NULL,
    PRIMARY KEY (saved_paper_id, author_order),
    CONSTRAINT fk_saved_paper_authors
        FOREIGN KEY (saved_paper_id) REFERENCES saved_papers (id) ON DELETE CASCADE
);

CREATE TABLE saved_paper_tags (
    saved_paper_id UUID NOT NULL,
    tag VARCHAR(80) NOT NULL,
    PRIMARY KEY (saved_paper_id, tag),
    CONSTRAINT fk_saved_paper_tags
        FOREIGN KEY (saved_paper_id) REFERENCES saved_papers (id) ON DELETE CASCADE
);

CREATE INDEX idx_saved_papers_status ON saved_papers (reading_status);
CREATE INDEX idx_saved_papers_saved_at ON saved_papers (saved_at);
CREATE INDEX idx_saved_paper_tags_tag ON saved_paper_tags (tag);
