const functions = require('firebase-functions');
const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');

// Initialize Firebase Admin SDK without default service connections.
// Passing an empty object prevents it from trying to connect to Firestore
// or Realtime Database, which you are not using in this function.
admin.initializeApp({});

// --- Main Callable Function ---
exports.mintSupabaseToken = functions.runWith({
    // Make the secret available to the function as an environment variable
    secrets: ["SUPABASE_JWT_SECRET"] 
}).https.onCall(async (data, context) => {

    // 1. Authentication Check
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'The request must be authenticated with a Firebase user ID token.'
        );
    }

    const firebaseUid = context.auth.uid;

    // 2. JWT Secret Retrieval
    // The secret is automatically populated into process.env by the 'secrets' configuration above.
    const supabaseJwtSecret = process.env.SUPABASE_JWT_SECRET;

    if (!supabaseJwtSecret) {
        console.error("SUPABASE_JWT_SECRET environment variable is not set.");
        throw new functions.https.HttpsError(
            'internal',
            'Server configuration error: Supabase secret missing.'
        );
    }

    // 3. Define the Supabase-Compatible Payload
    const nowSec = Math.floor(Date.now() / 1000);
    const expSec = nowSec + (60 * 60); // Token expires in 1 hour, which is the default for Supabase

    const payload = {
        sub: firebaseUid, // 'sub' (Subject) must be the user's UID
        role: 'authenticated', // This role is required for RLS
        iat: nowSec, // Issued At (as integer)
        exp: expSec, // Expiration Time
    };

    try {
        // 4. Mint (Sign) the custom JWT
        const supabaseToken = jwt.sign(payload, supabaseJwtSecret);

        // 5. Return the token to the Flutter client
        return { access_token: supabaseToken };
    } catch (error) {
        console.error("Error minting Supabase token:", error);
        throw new functions.https.HttpsError(
            'internal',
            'Failed to generate Supabase authentication token.'
        );
    }
});