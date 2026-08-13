import { supabase } from "../../lib/supabase";

export async function signUpWithEmail({ name, email, password }) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: name,
      },
    },
  });

  if (error) {
    console.error("SIGNUP ERROR:", error);
    throw error;
  }

  console.log("SIGNUP AUTH SUCCESS:", data);

  return data;
}

export async function signInWithEmail({ email, password }) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    console.error("LOGIN ERROR:", error);
    throw error;
  }

  return data;
}

export async function signInWithGoogle() {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${window.location.origin}/auth/callback`,
    },
  });

  if (error) {
    console.error("GOOGLE LOGIN ERROR:", error);
    throw error;
  }

  return data;
}

export async function ensureCitizenProfile(user) {
  if (!user) return;

  const { data: existing, error } = await supabase
    .from("profiles")
    .select("id")
    .eq("id", user.id)
    .maybeSingle();

  if (error) {
    throw error;
  }

  if (!existing) {
    const { error: insertError } = await supabase
      .from("profiles")
      .insert({
        id: user.id,
        name: user.user_metadata?.full_name || user.email,
        email: user.email,
        role: "citizen",
      });

    if (insertError) {
      throw insertError;
    }
  }
}

export async function getProfile(userId) {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (error) {
    throw error;
  }

  return data;
}

export async function getSession() {
  const { data, error } = await supabase.auth.getSession();

  if (error) {
    throw error;
  }

  return data.session;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();

  if (error) {
    throw error;
  }
}