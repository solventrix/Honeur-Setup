class DatabaseConnectionDetails:

    def __init__(self, db_host, db_port, db_name, db_username, db_password, db_schema):
        self._db_host = db_host
        self._db_port = db_port
        self._db_name = db_name
        self._db_username = db_username
        self._db_password = db_password
        self._db_schema = db_schema

    @property
    def host(self):
        return self._db_host

    @property
    def port(self):
        return self._db_port

    @property
    def name(self):
        return self._db_name

    @property
    def username(self):
        return self._db_username

    @property
    def password(self):
        return self._db_password

    @property
    def schema(self):
        return self._db_schema

    def connect_string(self):
        return f"postgresql+psycopg2://{self.username}:{self.password}@{self.host}:{self.port}/{self.name}"

    def __str__(self):
        return f"host={self.host}, port={self.port}, name={self.name}, username={self.username}, schema={self.schema}"
