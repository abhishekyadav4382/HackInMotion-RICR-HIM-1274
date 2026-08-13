import { Routes, Route, Navigate } from "react-router-dom";

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/login" replace />} />

      <Route path="/login" element={<div>Login Page</div>} />

      <Route path="/signup" element={<div>Signup Page</div>} />

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}