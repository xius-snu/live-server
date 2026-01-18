# Deploying to Render

This guide will walk you through deploying your `LiveServer` to Render for free.

## Prerequisites
- A [GitHub](https://github.com/) account.
- A [Render](https://render.com/) account (you can sign up with GitHub).

## Step 1: Push to GitHub
Since we just initialized a local Git repository, you need to push it to a new GitHub repository.

1.  **Create a New Repo**: Go to [GitHub - New Repository](https://github.com/new).
    - Name it `live-server` (or anything you like).
    - **Do not** check "Initialize with README", .gitignore, or license.
    - Click **Create repository**.

2.  **Push Code**: Copy the commands under "**…or push an existing repository from the command line**" and paste them into your terminal here. They will look like this:
    ```bash
    git remote add origin https://github.com/YOUR_USERNAME/live-server.git
    git branch -M main
    git push -u origin main
    ```

## Step 2: Deploy on Render
1.  Go to your [Render Dashboard](https://dashboard.render.com/).
2.  Click **New +** -> **Web Service**.
3.  Select **Build and deploy from a Git repository**.
4.  Connect your GitHub account if prompted, and select the `live-server` repository you just created.
5.  **Configure the Service**:
    - **Name**: `live-server` (or whatever you want)
    - **Region**: Choose one close to you (e.g., Oregon, Frankfurt).
    - **Branch**: `main`
    - **Runtime**: `Node`
    - **Build Command**: `npm install` (default is correct)
    - **Start Command**: `npm start` (default is correct)
    - **Instance Type**: Select **Free**.

6.  **Environment Variables** (Crucial Step):
    - Scroll down to "Environment Variables" section.
    - Click **Add Environment Variable**.
    - **Key**: `REDIS_URL`
    - **Value**: `rediss://default:AYfAAAIncDJhNjc1YWIyZGY1YTc0NmUyODQxMjNhYjkzZmVmZWNmZnAyMzQ3NTI@helpful-marlin-34752.upstash.io:6379`
    - *Note: Render automagically sets the `PORT` variable, so you don't need to add that.*

7.  Click **Create Web Service**.

## Step 3: Wait and Test
Render will start building your app. Watch the logs. When it says "Server started on...", you are live!
Copy the URL (e.g., `https://live-server-xyz.onrender.com`) from the top left.
