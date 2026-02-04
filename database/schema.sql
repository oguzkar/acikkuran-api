-- AcikKuran Database Schema
-- ============================================

-- Surahs (Chapters)
CREATE TABLE acikkuran_surahs (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,                    -- Turkish name
    name_en VARCHAR(255),                           -- English name
    name_original VARCHAR(255),                     -- Arabic name
    name_translation_tr TEXT,                       -- Turkish translation of name
    name_translation_en TEXT,                       -- English translation of name
    slug VARCHAR(255) UNIQUE NOT NULL,
    verse_count INTEGER NOT NULL,
    page_number INTEGER,                            -- Starting page
    audio TEXT,                                     -- Turkish audio URL
    duration INTEGER,                               -- Turkish audio duration (seconds)
    audio_en TEXT,                                  -- English audio URL
    duration_en INTEGER,                            -- English audio duration (seconds)
    created_at TIMESTAMP DEFAULT NOW()
);

-- Verses (Ayahs)
CREATE TABLE acikkuran_verses (
    id SERIAL PRIMARY KEY,
    surah_id INTEGER NOT NULL REFERENCES acikkuran_surahs(id) ON DELETE CASCADE,
    verse_number INTEGER NOT NULL,
    verse TEXT NOT NULL,                            -- Arabic text with vowels
    verse_simplified TEXT,                          -- Simplified Arabic text
    verse_without_vowel TEXT,                       -- Arabic text without vowels
    page INTEGER NOT NULL,                          -- Page number in Quran
    juz_number INTEGER,                             -- Juz (part) number
    transcription TEXT,                             -- Turkish transcription
    transcription_en TEXT,                          -- English transcription
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(surah_id, verse_number)
);

-- Authors (Translators)
CREATE TABLE acikkuran_authors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    language VARCHAR(10) DEFAULT 'tr',             -- 'tr' or 'en'
    url TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Translations
CREATE TABLE acikkuran_translations (
    id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES acikkuran_authors(id) ON DELETE CASCADE,
    verse_id INTEGER NOT NULL REFERENCES acikkuran_verses(id) ON DELETE CASCADE,
    surah_id INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(author_id, verse_id)
);

-- Footnotes
CREATE TABLE acikkuran_footnotes (
    id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES acikkuran_authors(id) ON DELETE CASCADE,
    verse_id INTEGER NOT NULL REFERENCES acikkuran_verses(id) ON DELETE CASCADE,
    surah_id INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    number INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Root Characters (Arabic letters)
CREATE TABLE acikkuran_rootchars (
    id SERIAL PRIMARY KEY,
    arabic VARCHAR(10) NOT NULL,
    latin VARCHAR(10) NOT NULL
);

-- Roots (Word Etymology)
CREATE TABLE acikkuran_roots (
    id SERIAL PRIMARY KEY,
    rootchar_id INTEGER REFERENCES acikkuran_rootchars(id),
    arabic VARCHAR(50),
    latin VARCHAR(50),
    transcription TEXT,                            -- Turkish transcription
    transcription_en TEXT,                         -- English transcription
    mean TEXT,                                     -- Turkish meaning
    mean_en TEXT                                   -- English meaning
);

-- Root Differences (Variations)
CREATE TABLE acikkuran_rootdiffs (
    id SERIAL PRIMARY KEY,
    root_id INTEGER NOT NULL REFERENCES acikkuran_roots(id) ON DELETE CASCADE,
    diff TEXT NOT NULL,
    count INTEGER DEFAULT 0
);

-- Verse Parts (Words in verses)
CREATE TABLE acikkuran_verseparts (
    id SERIAL PRIMARY KEY,
    verse_id INTEGER NOT NULL REFERENCES acikkuran_verses(id) ON DELETE CASCADE,
    root_id INTEGER REFERENCES acikkuran_roots(id),
    rootdiff_id INTEGER REFERENCES acikkuran_rootdiffs(id),
    surah_id INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    sort_number INTEGER NOT NULL,
    arabic TEXT NOT NULL,
    transcription_tr TEXT,
    transcription_en TEXT,
    translation_tr TEXT,
    translation_en TEXT,
    details JSONB,                                  -- Grammatical properties
    UNIQUE(verse_id, sort_number)
);

-- Root Words (Deprecated - kept for backwards compatibility)
CREATE TABLE acikkuran_rootwords (
    id SERIAL PRIMARY KEY,
    verse_id INTEGER REFERENCES acikkuran_verses(id) ON DELETE CASCADE,
    root_id INTEGER REFERENCES acikkuran_roots(id),
    surah_id INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    sort_number INTEGER NOT NULL,
    arabic TEXT NOT NULL,
    transcription TEXT,
    turkish TEXT
);

-- Root Verses (Word occurrences with roots)
CREATE TABLE acikkuran_rootverses (
    id SERIAL PRIMARY KEY,
    verse_id INTEGER NOT NULL REFERENCES acikkuran_verses(id) ON DELETE CASCADE,
    root_id INTEGER NOT NULL REFERENCES acikkuran_roots(id) ON DELETE CASCADE,
    rootdiff_id INTEGER REFERENCES acikkuran_rootdiffs(id),
    surah_id INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    sort_number INTEGER NOT NULL,
    arabic TEXT NOT NULL,
    transcription TEXT,
    turkish TEXT,
    detail_1 TEXT,
    detail_2 TEXT,
    detail_3 TEXT,
    detail_4 TEXT,
    detail_5 TEXT,
    detail_6 TEXT,
    detail_7 TEXT,
    detail_8 TEXT
);

-- ============================================
-- User Tables (for user-generated translations)
-- ============================================

-- User Translations
-- Note: user_id is a string (UUID from Hasura in production, or local ID in development)
CREATE TABLE acikkuran_user_translations (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    verse_id INTEGER NOT NULL REFERENCES acikkuran_verses(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, verse_id)
);

-- User Translation Footnotes
CREATE TABLE acikkuran_user_footnotes (
    id SERIAL PRIMARY KEY,
    user_translation_id INTEGER NOT NULL REFERENCES acikkuran_user_translations(id) ON DELETE CASCADE,
    verse_id INTEGER NOT NULL REFERENCES acikkuran_verses(id),
    user_id VARCHAR(255) NOT NULL,
    number INTEGER NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- Indexes for Performance
-- ============================================

-- Core indexes
CREATE INDEX idx_verses_surah_id ON acikkuran_verses(surah_id);
CREATE INDEX idx_verses_page ON acikkuran_verses(page);
CREATE INDEX idx_verses_juz_number ON acikkuran_verses(juz_number);
CREATE INDEX idx_translations_author_id ON acikkuran_translations(author_id);
CREATE INDEX idx_translations_verse_id ON acikkuran_translations(verse_id);
CREATE INDEX idx_translations_surah_verse ON acikkuran_translations(surah_id, verse_number);
CREATE INDEX idx_footnotes_verse_id ON acikkuran_footnotes(verse_id);
CREATE INDEX idx_footnotes_author_id ON acikkuran_footnotes(author_id);
CREATE INDEX idx_verseparts_verse_id ON acikkuran_verseparts(verse_id);
CREATE INDEX idx_verseparts_surah_verse ON acikkuran_verseparts(surah_id, verse_number);
CREATE INDEX idx_verseparts_root_id ON acikkuran_verseparts(root_id);
CREATE INDEX idx_rootwords_surah_verse ON acikkuran_rootwords(surah_id, verse_number);
CREATE INDEX idx_rootwords_root_id ON acikkuran_rootwords(root_id);
CREATE INDEX idx_rootverses_root_id ON acikkuran_rootverses(root_id);
CREATE INDEX idx_rootverses_surah_verse ON acikkuran_rootverses(surah_id, verse_number);
CREATE INDEX idx_rootverses_verse_id ON acikkuran_rootverses(verse_id);
CREATE INDEX idx_roots_rootchar_id ON acikkuran_roots(rootchar_id);

-- User translations indexes
CREATE INDEX idx_user_translations_user_id ON acikkuran_user_translations(user_id);
CREATE INDEX idx_user_translations_verse_id ON acikkuran_user_translations(verse_id);
CREATE INDEX idx_user_footnotes_user_translation_id ON acikkuran_user_footnotes(user_translation_id);
CREATE INDEX idx_user_footnotes_user_id ON acikkuran_user_footnotes(user_id);

-- Full-text search indexes (optional, for future use)
CREATE INDEX idx_verses_verse_gin ON acikkuran_verses USING gin(to_tsvector('simple', verse));
CREATE INDEX idx_translations_text_gin ON acikkuran_translations USING gin(to_tsvector('turkish', text));
