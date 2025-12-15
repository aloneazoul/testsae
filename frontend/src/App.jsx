import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import Layout from "@/components/partials/layout";
import BookSearch from "./pages/BookSearch";
import MyLoans from "./pages/MyLoans";
import Dashboard from "./pages/Dashboard";
import LoanManagement from "./pages/LoanManagement";
import BookManagement from "./pages/BookManagement";
import Authentification from "./pages/Authentification";

function App() {
  return (
    <Router>
      <Routes>
        <Route path='authentification' element={<Authentification />} />
        
        <Route element={<Layout />}>
          <Route index element={<Navigate to="/booksearch" replace />} />
          <Route path='/booksearch' element={<BookSearch />} />
          <Route path='/myloans' element={<MyLoans />} />
          <Route path='/dashboard' element={<Dashboard />} />
          <Route path='/loanmanagement' element={<LoanManagement />} />
          <Route path='/bookmanagement' element={<BookManagement />} />
        </Route>
      </Routes>
    </Router>
  );
}

export default App
