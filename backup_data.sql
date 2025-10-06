--
-- PostgreSQL database dump
--

\restrict Zggt21qQruDHwtmB1rO7bqHBPDT3ffXFhanirbu0vaNlLbZy2vgdJ3oVnhJUaVb

-- Dumped from database version 17.4
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transactions (id, sale_id, bundle_id, offer_id, sale_amount, sale_currency, sale_date, metadata, created_at, description) FROM stdin;
1	\N	2	1	1000.00	USD	2025-10-05 01:32:23.623425+00	{"note": "Test Smart Payout Transaction"}	2025-10-05 01:32:23.623425+00	\N
2	\N	2	\N	1000.00	USD	2025-10-05 04:01:54.874894+00	\N	2025-10-05 04:01:54.874894+00	Test Smart Payout Transaction
\.


--
-- Data for Name: payouts_v2; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payouts_v2 (id, payout_uuid, transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, notion_page_url, created_at, sent_at) FROM stdin;
1	b29bb67b-d392-44e0-a715-d216a8d92584	1	\N	\N	default	100.00	USD	queued	\N	2025-10-05 01:32:23.623425+00	\N
2	69c7d78a-de5b-4b11-aa0f-54725c41f2e9	2	\N	\N	default	100.00	USD	queued	\N	2025-10-05 04:01:54.874894+00	\N
\.


--
-- Name: payouts_v2_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payouts_v2_id_seq', 2, true);


--
-- Name: transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transactions_id_seq', 2, true);


--
-- PostgreSQL database dump complete
--

\unrestrict Zggt21qQruDHwtmB1rO7bqHBPDT3ffXFhanirbu0vaNlLbZy2vgdJ3oVnhJUaVb

