<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Database\Connection;
use LogicException;

final class SyncRevision
{
    /** The caller holds this lock until its catalog write commits or rolls back. */
    public static function next(Connection $connection): int
    {
        if ($connection->transactionLevel() === 0) {
            throw new LogicException('Sync revisions must be allocated inside a transaction.');
        }

        $row = $connection->table('sync_revisions')->where('id', 1)->lockForUpdate()->first();
        $version = (int) $row->version + 1;
        $connection->table('sync_revisions')->where('id', 1)->update(['version' => $version]);

        return $version;
    }
}
