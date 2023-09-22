// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct Users {
    // Default admin for all contracts.
    address admin;
    // A normal user.
    address alice;
    // Malicious user.
    address eve;
    // Server of the project
    address server;
}
