#!/usr/bin/env perl
use DBI;
use Env;
use File::Slurp;
use JSON;
use Mojolicious::Lite -signatures;

get '/up' => sub ($connection) {
    my $action = $connection->param('action');
    my $result = `sqlcmd -S mssql -U sa -P ${DATABASE_PASSWORD} -d ${DATABASE} -i "/actions/$action/tearUp.sql"`;
    $connection->render(text => $result);
};

get '/down' => sub ($connection) {
    my $action = $connection->param('action');
    my $result = `sqlcmd -S mssql -U sa -P ${DATABASE_PASSWORD} -d ${DATABASE} -i "/actions/$action/tearDown.sql"`;
    $connection->render(text => $result);
};

get '/assert' => sub ($connection) {
    my $action = $connection->param('action');
    my $json = read_file("/actions/$action/assert.json");
    my $assertions = decode_json($json);

    my $db = DBI->connect("dbi:ODBC:driver={/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.8.so.1.1};Server=mssql;database=${DATABASE};uid=sa;pwd=${DATABASE_PASSWORD};");

    my $result = {};
    foreach my $assertion (@{$assertions}) {
        my $query = $db->prepare($assertion->{statement});
        $query->execute();
        $result->{$assertion->{name}} = $query->fetchall_arrayref;
    }

    $db->disconnect();
    $connection->render(json => $result);
};

app->start;
