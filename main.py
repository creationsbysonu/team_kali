from typing import List, Dict
from pathlib import Path
import argparse

from rag.config import settings
from rag.models import DummyEmbedding, SimpleExtractiveGenerator, STEmbedding, E5Embedding
from rag.ingest import load_and_chunk_docs, DocChunk, ingest_to_db, ingest_to_mysql
from rag.pipeline import RAGPipeline
from rag.db import connect, init_db
from rag.db_mysql import connect_mysql, init_db_mysql


def build_index(pipeline: RAGPipeline, chunks: List[DocChunk]):
    texts = [c.text for c in chunks]
    metas = [c.source for c in chunks]
    pipeline.build_index(texts, metas)


def run_question(pipeline: RAGPipeline, question: str):
    print(pipeline.answer(question))


def ensure_sample_doc():
    sample = Path("data/docs/example.md")
    if sample.exists():
        return
    sample.write_text(
        """---
ministry: Ministry of Communications and Information Technology
title: E-Governance Service Guidelines 2082
upload_date: 2026-01-10
---
नेपाल सरकारको ई-शासन सेवाहरूको प्रयोग गर्दा नागरिकले अनलाइन आवेदन दिने, आवश्यक कागजात अपलोड गर्ने, स्थितिको अनुगमन गर्ने, र निर्णय सूचना प्राप्त गर्ने प्रक्रिया अपनाउँछन्। अतिरिक्त रूपमा, सेवा केन्द्रहरूमा सहायता उपलब्ध हुन्छ।
""",
        encoding="utf-8",
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build-index", action="store_true")
    parser.add_argument("--init-db", action="store_true")
    parser.add_argument("--ingest", action="store_true", help="Ingest docs into DB with embeddings")
    parser.add_argument("--build-index-from-db", action="store_true")
    parser.add_argument("--use-mysql", action="store_true", help="Use MySQL backend instead of SQLite")
    parser.add_argument("--use-st", action="store_true", help="Use SentenceTransformer embeddings")
    parser.add_argument("--mysql-host", type=str, default="localhost")
    parser.add_argument("--mysql-port", type=int, default=3306)
    parser.add_argument("--mysql-user", type=str, default="root")
    parser.add_argument("--mysql-password", type=str, default="")
    parser.add_argument("--mysql-db", type=str, default="rag")
    parser.add_argument("--question", type=str, default=None)
    args = parser.parse_args()

    ensure_sample_doc()

    # Default to E5Embedding (pure transformers, more stable)
    embedder = E5Embedding() if args.use_st else DummyEmbedding()
    generator = SimpleExtractiveGenerator()
    pipeline = RAGPipeline(embedder, generator)

    if args.init_db:
        if args.use_mysql:
            conn = connect_mysql(args.mysql_host, args.mysql_user, args.mysql_password, args.mysql_db, args.mysql_port)
            init_db_mysql(conn)
            conn.close()
            print("Initialized MySQL DB:", args.mysql_db)
        else:
            conn = connect(settings.db_path)
            init_db(conn)
            conn.close()
            print("Initialized SQLite DB at", settings.db_path)

    if args.ingest:
        if args.use_mysql:
            ingest_to_mysql(embedder, {
                "host": args.mysql_host,
                "port": args.mysql_port,
                "user": args.mysql_user,
                "password": args.mysql_password,
                "database": args.mysql_db,
            }, settings.data_dir)
            print("MySQL ingestion complete.")
        else:
            ingest_to_db(embedder, settings.data_dir, settings.db_path)
            print("SQLite ingestion complete.")

    if args.build_index:
        chunks = load_and_chunk_docs(settings.data_dir)
        build_index(pipeline, chunks)
        print("Index built with", len(chunks), "chunks")

    if args.build_index_from_db:
        if args.use_mysql:
            conn = connect_mysql(args.mysql_host, args.mysql_user, args.mysql_password, args.mysql_db, args.mysql_port)
            pipeline.index.build_from_mysql(conn)
            conn.close()
            print("Index built from MySQL with", len(pipeline.index.texts), "chunks")
        else:
            conn = connect(settings.db_path)
            pipeline.index.build_from_db(conn)
            conn.close()
            print("Index built from SQLite with", len(pipeline.index.texts), "chunks")

    if args.question:
        # Prefer DB-backed index if available
        if pipeline.index.nn is None:
            if args.use_mysql:
                conn = connect_mysql(args.mysql_host, args.mysql_user, args.mysql_password, args.mysql_db, args.mysql_port)
                pipeline.index.build_from_mysql(conn)
                conn.close()
            else:
                conn = connect(settings.db_path)
                pipeline.index.build_from_db(conn)
                conn.close()
            if pipeline.index.nn is None:
                # Fallback to direct files
                chunks = load_and_chunk_docs(settings.data_dir)
                build_index(pipeline, chunks)
        run_question(pipeline, args.question)


if __name__ == "__main__":
    main()
