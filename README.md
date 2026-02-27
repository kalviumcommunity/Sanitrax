🌍 Sanitrax – Smart Garbage Truck Tracking System

Sanitrax is a city-level waste collection tracking system that improves communication between residents, drivers, and municipal authorities.

📌 Problem Statement

Residents often don’t receive timely updates about garbage collection schedules or delays. This leads to missed pickups, inconvenience, and poor coordination with municipal services.

💡 Solution

Sanitrax provides real-time tracking and smart notifications within a specific city.

When a driver logs in:

📍 GPS location is sent periodically

⚡ Backend stores only the latest location (no full history)

🔄 Location is cached in Redis for fast access

📡 WebSockets broadcast live updates to users in that area

🗺 Users can see the truck moving on the map

This ensures scalability by tracking only active trucks.

🚀 Without GPS (Alternative Model)

Sanitrax can also work using:

📅 Route scheduling

⏱ Estimated arrival time windows

🔔 Status-based updates

📩 SMS/push notification when the truck enters a zone

Users won’t see live movement but will know arrival timing.

🎯 Core Tracking Methods

Sanitrax uses one of the following:

GPS from driver’s phone

Status/scan updates

Route-time prediction

Manual driver updates

It can support:
A) Live map
B) Arrival window
C) Both (recommended model)

🔥 Key Features

Real-time truck tracking

Track only active trucks

Latest-location storage

Redis caching for performance

WebSocket-based live updates

Role-based access (Resident, Driver, Admin)

Automated notifications

🛠 Tech Stack

Frontend: Flutter

Authentication: Firebase Auth

Database: Cloud Firestore

Backend: Node.js / Cloud Functions

Caching: Redis

Real-time: WebSockets

Notifications: Firebase Cloud Messaging (FCM)