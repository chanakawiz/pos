<?php

declare(strict_types=1);

namespace App\Traits;

use App\Services\SyncRevision;
use LogicException;

/** Keep catalog writes and their globally ordered checkpoint in the same transaction. */
trait TracksSyncVersion
{
    public function save(array $options = [])
    {
        return $this->getConnection()->transaction(function () use ($options) {
            $this->version = SyncRevision::next($this->getConnection());
            $saved = parent::save($options);
            if ($saved) {
                $this->getConnection()->table('sync_tombstones')
                    ->where('entity_type', $this->getTable())
                    ->where('entity_uuid', $this->uuid)->delete();
            }

            return $saved;
        });
    }

    protected function incrementOrDecrement($column, $amount, $extra, $method)
    {
        if ($column === 'version') {
            throw new LogicException('Sync version is managed by the revision sequence.');
        }

        return $this->getConnection()->transaction(function () use ($column, $amount, $extra, $method) {
            $extra['version'] = SyncRevision::next($this->getConnection());
            $result = parent::incrementOrDecrement($column, $amount, $extra, $method);
            $this->syncOriginalAttribute('version');

            return $result;
        });
    }

    public function delete()
    {
        if (! $this->exists) {
            return parent::delete();
        }

        return $this->getConnection()->transaction(function () {
            $version = SyncRevision::next($this->getConnection());
            $deleted = parent::delete();
            if ($deleted) {
                if ($this->isForceDeleting()) {
                    $this->getConnection()->table('sync_tombstones')->updateOrInsert(
                        ['entity_type' => $this->getTable(), 'entity_uuid' => $this->uuid],
                        ['version' => $version, 'deleted_at' => now()]
                    );
                } else {
                    // SoftDeletes updates only its timestamp columns, so persist the revision explicitly.
                    $this->getConnection()->table($this->getTable())->where($this->getKeyName(), $this->getKey())
                        ->update(['version' => $version]);
                    $this->version = $version;
                    $this->syncOriginalAttribute('version');
                }
            }

            return $deleted;
        });
    }
}
