""" Strategy class for application/vnd.sqlite3 """
from dataclasses import dataclass
import sqlite3
from typing import Any, Dict, Optional

from oteapi.models.resourceconfig import ResourceConfig
from oteapi.plugins.factories import StrategyFactory


def create_connection(db_file):
    """create a database connection to the SQLite database
        specified by db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except sqlite3.Error as exc:
        print(exc)

    return conn


@dataclass
@StrategyFactory.register(("mediaType", "application/vnd.sqlite3"))
class SqliteParseStrategy:

    resource_config: ResourceConfig

    def parse(
        self, session: Optional[Dict[str, Any]] = None  # pylint: disable=W0613
    ) -> Dict:

        if session is None:
            raise ValueError("Missing session")
        if "sqlquery" in session:
            cn = create_connection(session["filename"])
            cur = cn.cursor()
            rows = cur.execute(session["sqlquery"]).fetchall()
            return dict(result=rows)
        else:
            return dict(result="No query given")

    def initialize(
        self, session: Optional[Dict[str, Any]] = None  # pylint: disable=W0613
    ) -> Dict:
        """Initialize"""
        return dict()
