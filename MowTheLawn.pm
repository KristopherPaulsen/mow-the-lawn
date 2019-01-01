#!/usr/bin/env perl
package MowTheLawn;
use strict;
use Getopt::Long;
use Time::HiRes qw(usleep);

$|++; # Buffer immediatly!

GetOptions(
    'mower=s'          => \(my $mower = '`.=. '),
    'grass=s'          => \(my $grass = ','),
    'cut-grass=s'      => \(my $cut_grass = '_'),
    'mower-color=s'    => \(my $mower_color = "0"),
    'lawn-length=s'    => \(my $lawn_length = 20),
    'lawn-color=s'     => \(my $lawn_color = "38;5;106"),
    'speed=s'          => \(my $speed = 100),
    'pid=s'            => \(my $pid = $$ - 1),
    'loop-without-pid' => \(my $loop_without_pid),
);

# ------------------------------------------------------------------------------

sub sleep_in_ms {
    my $speed = shift;
    usleep($speed * 1000);
}

sub splice_random {
    my $array = shift;

    return splice(@$array, rand @$array, 1);
}

sub process_still_running {
    return $loop_without_pid || kill(0, $pid);
}

sub build_lawn {
    my ($lawn_length, $grass) = @_;

    return [
        map { $grass } (0..$lawn_length)
    ];
}

sub join_with_color {
    my $array = shift || [];
    my $color = shift || '';

    return "\e[$color" . "m" . join('', @$array) . "\e[0m";
}

sub print_with_color {
    my $args = shift;

    print "\r" . join_with_color($args->{'cut_lawn'}, $lawn_color)
               . join_with_color($args->{'mower'}, $mower_color)
               . join_with_color($args->{'uncut_lawn'}, $lawn_color);
}

sub lawn_mower_enters {
    my $mower          = [split('', $mower)];
    my $uncut_lawn     = build_lawn($lawn_length, $grass);
    my $entering_mower = [];

    while (scalar @$mower && process_still_running()) {
        print_with_color({
            uncut_lawn => $uncut_lawn,
            mower      => $entering_mower,
        });

        my $part = pop(@$mower);
        shift(@$uncut_lawn);
        unshift(@$entering_mower, $part);

        sleep_in_ms($speed);
    }
}

sub lawn_mower_mows {
    my $mower      = [split('', $mower)];
    my $uncut_lawn = build_lawn($lawn_length - scalar @$mower, $grass);
    my $cut_lawn   = [];

    while (scalar @$uncut_lawn && process_still_running()) {

        print_with_color({
            cut_lawn   => $cut_lawn,
            mower      => $mower,
            uncut_lawn => $uncut_lawn,
        });

        pop(@$uncut_lawn);
        unshift(@$cut_lawn, $cut_grass);

        sleep_in_ms($speed);
    }
}

sub lawn_mower_leaves {
    my $mower    = [split('', $mower)];
    my $cut_lawn = build_lawn($lawn_length - scalar @$mower, $cut_grass);

    while (scalar @$mower && process_still_running()) {
        print_with_color({
            cut_lawn => $cut_lawn,
            mower    => $mower,
        });

        pop(@$mower);
        push(@$cut_lawn, $cut_grass);

        sleep_in_ms($speed);
    }
}

sub regrow_lawn {
    my $cut_lawn      = build_lawn($lawn_length, $cut_grass);
    my $idxs_to_visit = [0..scalar @$cut_lawn - 1];

    while (scalar @$idxs_to_visit && process_still_running()) {
        my $random_idx = splice_random($idxs_to_visit);

        $cut_lawn->[$random_idx] = $grass;

        print_with_color({
            cut_lawn => $cut_lawn,
        });

        sleep_in_ms($speed / 1.3);
    }
}

sub main {
    while (process_still_running()) {
        lawn_mower_enters();

        lawn_mower_mows();

        lawn_mower_leaves();

        regrow_lawn();

        sleep_in_ms($speed);
    }
}

main();

1;
