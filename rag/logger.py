"""
Structured logging system to replace print statements
"""
import logging
from datetime import datetime
from pathlib import Path
import sys


class ColoredFormatter(logging.Formatter):
    """Colored console formatter."""
    
    COLORS = {
        'DEBUG': '\033[36m',    # Cyan
        'INFO': '\033[32m',     # Green
        'WARNING': '\033[33m',  # Yellow
        'ERROR': '\033[31m',    # Red
        'CRITICAL': '\033[35m', # Magenta
    }
    RESET = '\033[0m'
    
    def format(self, record):
        log_color = self.COLORS.get(record.levelname, self.RESET)
        record.levelname = f"{log_color}{record.levelname}{self.RESET}"
        return super().format(record)


def setup_logger(name: str = "RAG", log_dir: Path = Path("logs")) -> logging.Logger:
    """Setup structured logger with file and console handlers."""
    
    # Create logger
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    
    # Remove existing handlers
    logger.handlers.clear()
    
    # Create logs directory
    log_dir.mkdir(exist_ok=True)
    
    # File handler (detailed logs)
    log_file = log_dir / f"rag_{datetime.now().strftime('%Y%m%d')}.log"
    file_handler = logging.FileHandler(log_file, encoding='utf-8')
    file_handler.setLevel(logging.DEBUG)
    file_formatter = logging.Formatter(
        '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(file_formatter)
    
    # Console handler (important logs only)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_formatter = ColoredFormatter(
        '%(levelname)-8s | %(message)s'
    )
    console_handler.setFormatter(console_formatter)
    
    # Add handlers
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger


# Global logger instance
logger = setup_logger()


def log_info(message: str, **kwargs):
    """Log info message with optional context."""
    if kwargs:
        message = f"{message} | {kwargs}"
    logger.info(message)


def log_warning(message: str, **kwargs):
    """Log warning message with optional context."""
    if kwargs:
        message = f"{message} | {kwargs}"
    logger.warning(message)


def log_error(message: str, error: Exception = None, **kwargs):
    """Log error message with exception details."""
    if error:
        kwargs['error'] = str(error)
        kwargs['error_type'] = type(error).__name__
    if kwargs:
        message = f"{message} | {kwargs}"
    logger.error(message)


def log_debug(message: str, **kwargs):
    """Log debug message with optional context."""
    if kwargs:
        message = f"{message} | {kwargs}"
    logger.debug(message)
