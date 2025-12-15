import React, { useState } from "react";
import { useLocation, Link, Outlet } from "react-router-dom";
import { createPageUrl } from "@/lib/utils";
import { AnimatePresence, motion } from "framer-motion";

import {
    BookOpen,
    Search,
    LayoutDashboard,
    BookCopy,
    LogOut,
    Menu,
    X,
    Library,
    ClipboardList
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export default function Layout({currentPageName }) {
    const location = useLocation();
    const [sidebarOpen, setSidebarOpen] = useState(false);

    const navItems = [
        { name: "Recherche", page: "BookSearch", icon: Search, access: "all" },
        { name: "Mes Emprunts", page: "MyLoans", icon: BookCopy, access: "user" },
        { name: "Tableau de Bord", page: "Dashboard", icon: LayoutDashboard, access: "librarian" },
        { name: "Gestion Livres", page: "BookManagement", icon: Library, access: "librarian" },
        { name: "Gestion Emprunts", page: "LoanManagement", icon: ClipboardList, access: "librarian" },
    ];

    const filteredNavItems = navItems.filter(item => {
        if (item.access === "all") return true;
        return true;
    });

    const handleLogout = () => {
        console.log("Déconnexion...");
    };

    return (
        <div className="min-h-screen bg-[#faf9f6]">
            {/* Header */}
            <header className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-lg border-b border-gray-100 shadow-sm">
                <div className="flex items-center justify-between px-4 md:px-8 h-16">
                    <div className="flex items-center gap-3">
                        <Button
                            variant="ghost"
                            size="icon"
                            className="md:hidden"
                            onClick={() => setSidebarOpen(!sidebarOpen)}
                        >
                            {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
                        </Button>

                        <Link to={createPageUrl()} className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-linear-to-br from-[#1e3a5f] to-[#2d5a8f] flex items-center justify-center">
                                <BookOpen className="w-5 h-5 text-white" />
                            </div>
                            <div className="hidden sm:block">
                                <h1 className="text-lg font-bold gradient-text">BiblioTech</h1>
                                <p className="text-xs text-gray-500">Bibliothèque Universitaire</p>
                            </div>
                        </Link>
                    </div>

                    <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="flex items-center gap-3 hover:bg-gray-100 rounded-xl py-6">
                                <div className="text-right hidden sm:block">
                                    <p className="text-sm font-medium text-gray-900">userName</p>
                                    <p className="text-xs text-[#d4af37] capitalize">userRole</p>
                                </div>
                                <Avatar className="w-9 h-9 border-2 border-[#d4af37]">
                                    <AvatarFallback className="bg-[#1e3a5f] text-white text-sm">
                                        userFullname
                                    </AvatarFallback>
                                </Avatar>
                            </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end" className="w-56">
                            <div className="px-3 py-2">
                                <p className="text-sm font-medium">userFullname</p>
                                <p className="text-xs text-gray-500">userMail</p>
                            </div>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem onClick={handleLogout} className="text-red-600">
                                <LogOut className="w-4 h-4 mr-2" />
                                Déconnexion
                            </DropdownMenuItem>
                        </DropdownMenuContent>
                    </DropdownMenu>
                </div>
            </header>

            {/* Sidebar */}
            <aside className={`
        fixed left-0 top-16 bottom-0 w-64 bg-white border-r border-gray-100 z-40
        transform transition-transform duration-300 ease-in-out
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
        md:translate-x-0
      `}>
                <nav className="p-4 space-y-2">
                    {filteredNavItems.map((item) => (
                        <Link
                            key={item.page}
                            to={createPageUrl(item.page)}
                            onClick={() => setSidebarOpen(false)}
                            className={`
                transition duration-300 ease-in-out hover:bg-linear-to-tr hover:from-blue-900/10 hover:to-yellow-500/10 flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium
                ${currentPageName === item.page
                                    ? 'bg-linear-to-tr from-blue-900 to-blue-700 text-white'
                                    : 'text-gray-700 hover:text-[#1e3a5f]'
                                }
              `}
                        >
                            <item.icon className="w-5 h-5" />
                            {item.name}
                        </Link>
                    ))}
                </nav>

                <div className="absolute bottom-0 left-0 right-0 p-4">
                    <div className="bg-linear-to-br from-[#1e3a5f]/5 to-[#d4af37]/10 rounded-2xl p-4">
                        <p className="text-xs text-gray-600 mb-2">Besoin d'aide ?</p>
                        <p className="text-xs text-gray-500">Accueil bibliothèque : Bâtiment A, RDC</p>
                    </div>
                </div>
            </aside>

            {/* Overlay mobile */}
            {sidebarOpen && (
                <div
                    className="fixed inset-0 bg-black/20 z-30 md:hidden"
                    onClick={() => setSidebarOpen(false)}
                />
            )}

            {/* Main Content */}
            <main className="md:ml-64 pt-16 min-h-screen overflow-hidden">
                <div className="p-4 md:p-8">
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={location.pathname}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.25, ease: "easeOut" }}
                        >
                            <Outlet />
                        </motion.div>
                    </AnimatePresence>
                </div>
            </main>
        </div>
    );
}