/**
 * EXPERIMMO — supabase-client.js
 * Compatibility shim: replaces Supabase with calls to the FastAPI backend.
 * Provides supabase.auth.getUser() and a basic from() query builder.
 */

import apiClient from './api-client.js';

const _getLocalUser = () => {
    try {
        const s = localStorage.getItem('exper_immo_user');
        return s ? JSON.parse(s) : null;
    } catch { return null; }
};

// ── Auth shim ───────────────────────────────────────────────
const authShim = {
    getUser: async () => {
        const user = _getLocalUser();
        return { data: { user }, error: null };
    },
    signOut: async () => {
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        return { error: null };
    },
};

// ── Query builder shim ──────────────────────────────────────
// Maps common supabase query patterns to REST API calls.
// Not 100% compatible — file-level rewrites are preferred — but
// this prevents import errors for files not yet migrated.
const _tableToEndpoint = (table) => {
    const map = {
        profiles:          '/users',
        users:             '/users',
        locataires:        '/locataires',
        proprietaires:     '/proprietaires',
        proprietes:        '/properties',
        contrats:          '/admin/contrats',
        paiements:         '/paiements',
        codes_inscription: '/admin/codes',
    };
    return map[table] || `/${table}`;
};

class QueryBuilder {
    constructor(table) {
        this._table    = table;
        this._endpoint = _tableToEndpoint(table);
        this._filters  = {};
        this._inFilter = null;
        this._limit    = null;
        this._countOnly = false;
    }
    select(cols, opts = {}) {
        if (opts.count === 'exact' && opts.head) this._countOnly = true;
        return this;
    }
    eq(col, val)   { this._filters[col] = val; return this; }
    in(col, vals)  { this._inFilter = { col, vals }; return this; }
    order()        { return this; }
    limit(n)       { this._limit = n; return this; }
    single()       { this._single = true; return this; }

    async _execute() {
        try {
            const params = new URLSearchParams();
            Object.entries(this._filters).forEach(([k, v]) => params.append(k, v));
            const url = this._endpoint + (params.toString() ? '?' + params.toString() : '');
            const data = await apiClient.get(url);
            const arr = Array.isArray(data) ? data : (data ? [data] : []);
            if (this._countOnly) return { count: arr.length, data: null, error: null };
            if (this._single)    return { data: arr[0] || null, error: null };
            return { data: arr, error: null };
        } catch (err) {
            return { data: null, error: err, count: 0 };
        }
    }

    then(resolve, reject) {
        return this._execute().then(resolve, reject);
    }
}

export const supabaseClient = {
    auth: authShim,
    from: (table) => new QueryBuilder(table),
};

export default supabaseClient;
