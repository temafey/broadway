<?php

declare(strict_types=1);

namespace Broadway\Snapshot;

use Broadway\Domain\AggregateRoot as AggregateRootInterface;

interface SnapshotInterface
{
    /**
     * Get playhead counter value.
     */
    public function getPlayhead(): int;

    /**
     * Get AggregateRoot object.
     */
    public function getAggregateRoot(): AggregateRootInterface;
}
