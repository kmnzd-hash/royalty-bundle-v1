--
-- PostgreSQL database dump
--

\restrict 3wGkrIj8dwhu4HTgpDnEE7QpARYgBU4ZsWY9Kl0hlS1SRpI7pGNHDnhlRC67eYh

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
-- Data for Name: payouts_v2; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payouts_v2 (id, payout_uuid, transaction_id, sale_id, recipient_entity, recipient_role, amount, currency, status, notion_page_url, created_at, sent_at) FROM stdin;
2	c95d285a-828b-49e3-90bd-829921cc617a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-10 04:58:35.506+00	\N
3	f4f324e3-cbfc-4fba-b9bd-a8be2301c8f0	\N	\N	1	creator	5000.00	USD	queued	\N	2025-10-10 04:58:36.6+00	\N
4	141e1564-7ce9-4d8c-ba38-28b61593b923	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-10 05:17:51.124+00	\N
5	51a19044-92c1-4bb0-9be3-21ccd40e9974	\N	\N	1	creator	5000.00	USD	queued	\N	2025-10-10 05:17:51.974+00	\N
6	02cb1269-5f60-48dd-b6fd-4ff66df40833	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-10 05:17:53.075+00	\N
7	93f25381-defa-4c6c-bc77-2a4d998b6226	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-10 05:17:54.089+00	\N
8	cbd0c0d9-fa10-4cde-b53b-ee7da4998306	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-10 05:21:06.265+00	\N
9	37b1c2a5-9aa9-409b-8cda-4d021c489039	\N	\N	1	creator	5000.00	USD	queued	\N	2025-10-10 05:21:07.013+00	\N
10	61fefa40-25b9-4a7e-a4fe-9b876fbf552f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-10 05:21:07.565+00	\N
11	da48a26a-ed62-43ef-bc34-84afb1072298	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-10 05:21:08.143+00	\N
12	476eff8e-ada1-4fb5-a5b9-a13d4f2a47e1	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-10 05:27:50.897+00	\N
13	86c7efc8-aa58-4911-852b-ee3467f7d905	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-10 05:27:51.593+00	\N
14	0394bbf6-ca14-4017-8567-956ee1040a25	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 12:26:15.883+00	\N
15	1554f4d2-bff5-4a98-a987-c265cf198f61	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 12:26:18.009+00	\N
16	051c5ca6-e3af-4056-b3a2-b9f7e20eb31c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 12:27:05.05+00	\N
17	dd2df401-2f28-4b5b-b372-7badc7ad9393	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 12:27:05.903+00	\N
18	ba139505-7783-415d-89a3-a3e6a92bcd64	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 12:36:58.85+00	\N
19	9d37d0f3-b1fd-4497-86a2-35a4f6099272	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 12:36:59.759+00	\N
20	eacae9ed-44a2-4fc2-b48f-5a8faf3bfa57	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 12:56:16.017+00	\N
21	8f1bd9f1-9527-439d-b4e0-c3a94d96744e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 12:56:17.319+00	\N
22	1098c423-e34d-4c48-b9e4-08242f0ef70e	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 12:56:42.62+00	\N
23	08ac3f23-3149-4d34-9755-eb25d992a0cd	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 12:56:43.317+00	\N
24	d42420c8-d9df-44fe-9e9c-bbdf18a1886f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 13:03:15.047+00	\N
25	0eeccef2-2524-4993-bbb7-fb5f0875699b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 13:03:15.774+00	\N
26	f59e7eab-8a12-4fd0-becb-0f3aef59eec9	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 13:30:38.58+00	\N
27	dbb68a3f-c6b1-4c52-9e4b-db31a94a5e20	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 13:30:40.127+00	\N
28	c1f67b13-1947-4e7c-93a7-693f8bd73614	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 13:51:47.228+00	\N
29	f54148ff-0a06-4a26-b01c-cbdd0d2a6aff	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 13:51:48.763+00	\N
30	b77ae0e5-d525-47a7-bfc2-281b7f9d7ff3	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 14:15:45.879+00	\N
31	cb14af72-a2f8-4040-bc53-a1daf3e94440	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 14:15:46.767+00	\N
32	29274c1b-c3ba-404d-afbd-ec36a1a2cf7f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 14:36:55.368+00	\N
33	57a9c3c8-1259-46e2-a945-14cd3ceed274	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 14:36:56.63+00	\N
34	3d7aef7e-8d4e-4ab0-afa7-29c0acf87c05	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 14:51:42.395+00	\N
35	a613f59e-bf85-44c6-af33-bbc8523e56fa	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 14:51:43.87+00	\N
36	3fb88813-5b20-4642-969d-518773cba0f8	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 15:17:06.614+00	\N
37	d849e01b-7b5f-41b3-9891-c7b7404d5754	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 15:17:08.389+00	\N
38	0eab0999-31c2-4d3b-bffd-fe636e0b1aa1	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 15:37:36.912+00	\N
39	c6549e81-8033-4a00-a606-32c6846d30e2	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 15:37:38.69+00	\N
40	c7a439a0-7a55-4ac6-a28f-0386ae78a18b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 15:51:44.98+00	\N
41	01128277-3d04-4b38-a763-50e94a8a7fcf	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 15:51:46.498+00	\N
42	c527fb8a-3d2c-470b-8d63-bd4b3f59d873	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 16:21:40.62+00	\N
43	5f2e9867-a2ea-4d22-905a-2d8c99623754	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 16:21:41.999+00	\N
44	1c816899-9627-449b-a87c-7a0d86891297	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 16:41:02.029+00	\N
45	22b6cae0-0ce9-4d83-b399-02a411bc2acc	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 16:41:03.149+00	\N
46	fdb339fa-9251-4204-a4c5-0a7a065221ed	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 16:52:10.149+00	\N
47	2e064ae2-95e1-4a24-afc0-8e36ce331522	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 16:52:10.94+00	\N
48	9fc03791-aa38-457a-932c-9c38c59c2f1d	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 17:15:15.57+00	\N
49	4ee4b94f-ed61-40f7-a83c-c8cbd79db9ea	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 17:15:16.829+00	\N
50	c2d93a06-47cd-4333-aa63-dc517bc17f59	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 17:28:52.179+00	\N
51	bb76fd3b-81e1-4d38-a021-7920f60df5e1	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 17:28:53.431+00	\N
52	814237ed-942f-479a-8e34-b28a1f19688e	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 17:40:18.683+00	\N
53	f946c319-ecb8-4cc1-8c3d-10424423e4ee	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 17:40:19.899+00	\N
54	5c71dc72-c132-446c-bd4e-8eb85c3d8847	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 17:51:42.071+00	\N
55	3b323194-83ca-4186-953c-3c1b3eca6355	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 17:51:43.205+00	\N
56	08935c92-de57-48f8-8479-132dbcb9816d	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 18:24:31.773+00	\N
57	b8215b0e-61e4-4866-9ea3-ef0d876d7a96	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 18:24:32.755+00	\N
58	63d2b858-2def-4990-aa63-d28dc7f579cc	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 18:42:10.786+00	\N
59	dd3edec9-a54e-4e94-b81f-05a020a44b67	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 18:42:12.08+00	\N
60	55964b6f-9fcf-483e-a410-911288aff3f1	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 18:53:30.076+00	\N
61	c09d628f-23fa-43d3-8f85-4e2a8733a87e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 18:53:31.813+00	\N
62	a7baea29-3ee8-40c9-b90c-ed807e6bfcfd	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 19:13:52.644+00	\N
63	29901ca7-9121-41fb-89e2-70931b1d3b4d	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 19:13:53.845+00	\N
64	38d82d26-3a45-42a8-8cda-4b42de92d81f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 19:25:09.921+00	\N
65	3b559338-afa1-4bba-8243-9341336d3c35	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 19:25:11.272+00	\N
66	def52105-7906-4703-9e4b-cbb700d64913	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 19:37:43.591+00	\N
67	8669d15b-99cb-47e7-a470-f4ffcb47b6dc	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 19:37:44.557+00	\N
68	42cc15e2-dcc1-465c-9f31-e6dbb3e07cf6	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 19:51:30.984+00	\N
69	8f90e98f-a095-4b94-a8e4-73e137455f1f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 19:51:32.35+00	\N
70	d56529b6-224c-4c6b-8bb0-fb9a29c9b1a7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 20:19:43.28+00	\N
71	737f0912-5bba-45b7-ab45-7ea1ca73edc3	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 20:19:44.632+00	\N
72	1c9bbc41-3537-42ba-b66d-79a6418f5500	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 20:37:57.386+00	\N
73	07862d20-1fe5-41f1-82c1-8f41145a2b97	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 20:37:58.562+00	\N
74	ecb2ef1c-0530-49a5-99f4-08acd1bca688	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 20:51:09.938+00	\N
75	f6384b1f-908a-4ec3-9c9f-145d822eca28	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 20:51:11.231+00	\N
76	40329cac-b3cf-4ee0-99ce-870ce88298a0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 21:16:00.945+00	\N
77	de4f49c9-6ed4-49ee-981e-23be5ee8fd95	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 21:16:02.414+00	\N
78	c10676a0-fb41-41f7-afd9-e0deefd565be	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 21:37:10.489+00	\N
79	06df4be6-ffe7-4d25-8dcc-51b4111753ff	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 21:37:11.532+00	\N
80	90ad6f92-50c6-48d1-8898-4bff17c4958a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 21:51:44.849+00	\N
81	de4c53f5-a33a-4d46-a680-288c00c62428	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 21:51:46.122+00	\N
82	913b5614-1b19-4794-84b4-c1c8f6f6ad3c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 22:17:36.892+00	\N
83	821340a9-8f2a-4759-a154-7ec581301648	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 22:17:38.219+00	\N
84	09535022-4b10-4687-adab-00ec9c1aef0e	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 22:38:42.272+00	\N
85	a3b8f57c-a150-4081-b03e-8d4e6996251c	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 22:38:43.52+00	\N
86	a436ca6d-b75c-48e3-98af-c89d172bb5c0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 22:51:45.094+00	\N
87	abc1719d-ed37-4ac2-86d2-59d4b39dac53	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 22:51:46.411+00	\N
88	8f0f1fcf-f7b9-4a51-91f3-968fedfea8c6	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 23:17:50.285+00	\N
89	21082259-949b-426b-ab47-051dbd81eb12	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 23:17:51.594+00	\N
90	399246a5-be92-4043-9a94-eb6121dccb7a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 23:37:58.642+00	\N
91	eb8c47d9-3735-476b-bafe-721ebf161f06	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 23:37:59.95+00	\N
92	7db765c5-8d82-409b-829c-4558b0d25669	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-11 23:51:34.439+00	\N
93	0b06ebff-f8c1-4b0c-9d43-be501a981125	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-11 23:51:35.496+00	\N
94	d97553a2-b97c-4d8e-bfae-465559ab7926	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 01:40:32.738+00	\N
95	bbf60157-0144-4b8a-83e8-92a960fd2498	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 01:40:33.962+00	\N
96	644e333c-b6a9-4a68-a1fa-1e5d6446b1a3	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 02:52:15.848+00	\N
97	4d3d6480-5887-485d-81b0-3489baaa8523	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 02:52:16.903+00	\N
98	fae6e860-7eca-48b5-99f2-f8996308c724	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 02:57:43.217+00	\N
99	313f12fd-eaf6-4f60-adc9-42757bbee603	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 02:57:44.409+00	\N
100	df975546-6ee2-461c-8d68-4ccdca6d2749	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 03:34:10.322+00	\N
101	3b3b7b6f-5715-46c1-b08c-34ea73ea220e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 03:34:11.723+00	\N
102	865cc26f-2857-4af6-841b-c4ba7fe8a20e	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 03:53:15.052+00	\N
103	8e7e1177-f74c-482d-9b9d-da5bf841e96b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 03:53:16.923+00	\N
104	7445709d-33f1-4493-8db6-b1888294df4f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 04:23:24.508+00	\N
105	bb56cb54-0fef-42ab-ac9a-8487298da43a	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 04:23:25.841+00	\N
106	6dbd6ef6-96b7-48ae-9224-4fb5ae37b2e4	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 04:41:30.776+00	\N
107	4069b88c-3d08-4254-83bd-e23293864b29	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 04:41:32.474+00	\N
108	e80b9bf6-c51c-4b58-9e9a-686b86d55668	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 04:52:38.603+00	\N
109	0973284b-bea9-43bb-b90f-7f253a431b9f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 04:52:40.088+00	\N
110	f410ba66-2198-4602-9574-fdb0768ac1f3	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 05:18:20.235+00	\N
111	b2ed21ac-760f-436b-88a6-d72d8b1f4090	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 05:18:22.319+00	\N
112	8ecfffd2-40a4-433e-b2c2-ffa5f4911c67	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 05:39:01.803+00	\N
113	bf248992-98fe-471f-a6b0-fa7667f667c8	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 05:39:03.893+00	\N
114	b4df2b06-a519-4e71-9766-3575137f0e36	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 05:51:38.412+00	\N
115	9839ff67-2273-440c-a280-a65877df0fcc	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 05:51:39.712+00	\N
116	17ec1850-334a-4fff-8039-ae953320dd88	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 06:27:51.028+00	\N
117	3e60faf4-6828-45bc-972d-3cde335cf311	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 06:27:52.807+00	\N
118	a813b55f-e937-4714-b858-e1a54ba604c8	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 06:46:41.127+00	\N
119	ab594bb5-ec0d-4073-aed2-3d8e2d414a7b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 06:46:42.479+00	\N
120	0bb04823-6438-4c71-9b50-99851d4f2dfa	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 07:17:42.533+00	\N
121	c4bc0a54-f8ba-41bf-b97c-cbc64fc3a280	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 07:17:44.232+00	\N
122	0069b733-21f1-49a0-81a8-852f2fe19974	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 07:37:17.736+00	\N
123	90f2a607-5fca-4ff7-a96a-e56e5a1a5ac3	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 07:37:18.766+00	\N
124	7f438ab6-739c-43d3-b1a6-996b25e3738f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 07:51:28.294+00	\N
125	9ac1e26c-275b-4206-a403-1034695a1834	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 07:51:29.041+00	\N
126	1f3f0ead-b380-4882-9403-0ae10aac1657	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 08:23:42.825+00	\N
127	e1a56a3c-b431-420c-9de2-8314459968fb	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 08:23:43.77+00	\N
128	759ebab9-0e89-44c9-8a34-b6f038ed4da6	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 08:42:28.643+00	\N
129	467c4352-6ccc-4bd1-97ff-5ee926e378d7	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 08:42:29.992+00	\N
130	ce3df8e2-e249-49e9-9169-2bbfe0335381	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 08:53:32.703+00	\N
131	b7cf005e-6365-41a0-88fc-ab4de6517985	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 08:53:34.09+00	\N
132	486de17e-5439-449b-b5eb-cbbef6937892	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 09:18:31.682+00	\N
133	7f210fcb-dc10-43f9-92d9-a31a95be372b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 09:18:32.559+00	\N
134	3de31112-94f2-4467-8ac0-93fe17881dc3	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 09:37:23.137+00	\N
135	2c6f9261-d164-4b16-bddc-5b72d31af466	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 09:37:24.261+00	\N
136	573c931d-4e76-4cf8-9bc1-4dc1b39fb829	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 09:51:24.078+00	\N
137	f8acf07f-0e9b-4bf9-bb77-e12d7d7a26f8	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 09:51:25.382+00	\N
138	03dd387b-ad25-4dd3-a84a-3ff22769ff8c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 10:19:04.045+00	\N
139	18f251e9-61f6-4f20-b0e0-c36639aa9e2b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 10:19:05.373+00	\N
140	545ee19d-b8cd-40dd-94c3-23dd594246d9	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 10:39:22.806+00	\N
141	520726e5-a0a2-44e7-b932-c9d2387bd56d	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 10:39:24.051+00	\N
142	fd907e81-ea43-43bc-9385-3d26d1b17c2c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 10:51:43.34+00	\N
143	afed265a-5976-40dd-a1f7-b15a51951cfe	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 10:51:44.643+00	\N
144	b9cd251c-080a-4984-8db1-68e8d43cd64b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 11:14:56.067+00	\N
145	2233ad60-1330-4161-ae31-4fa01c0595e8	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 11:14:57.34+00	\N
146	4f6286f4-c303-4221-8516-ed1589737796	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 11:26:04.884+00	\N
147	7ded76d4-2a6e-4df1-a20d-f62571183a23	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 11:26:06.154+00	\N
148	e71041c0-94bd-48af-9f8c-2694d2c5ce19	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 11:38:39.804+00	\N
149	e33086d8-ce12-4535-95c3-5b9713bcb955	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 11:38:40.823+00	\N
150	767dc184-29ab-4541-a81e-040d91ab3e1c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 11:51:51.491+00	\N
151	9b834d48-a4c2-451a-ae0b-f318e237a91c	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 11:51:52.797+00	\N
152	42af67be-6506-4b8b-9026-3dca012bf80e	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 12:37:47.164+00	\N
153	16f07924-da7c-4580-9912-e4e11d311dd8	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 12:37:48.526+00	\N
154	74a724ad-799a-4ad1-818e-55b7d250a361	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 13:04:11.123+00	\N
155	4b65e57e-29fc-4ce1-8eec-cd62e7fb393a	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 13:04:12.498+00	\N
156	9f9d2b58-66cd-40c9-985d-c3f053dc2592	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 13:30:47.083+00	\N
157	4b001f63-1de4-4f4f-ad6a-8f5a63422f8f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 13:30:48.687+00	\N
158	3964c929-32c2-4076-97ab-eb9b58704183	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 13:51:41.331+00	\N
159	4e357ee2-6717-48e0-8611-a1ecd07c45de	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 13:51:42.613+00	\N
160	9a4666e1-423f-4844-921c-157700e680f8	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 14:16:48.961+00	\N
161	4fbed0bd-2f27-49c8-8157-09393f5190a2	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 14:16:49.855+00	\N
162	42a0c08b-6fa2-454b-9124-2579702df3ef	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 14:38:16.83+00	\N
163	2e1784dd-4d61-4900-8cc6-d12814eb9117	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 14:38:18.073+00	\N
164	d4cf81b4-a642-4493-b414-2ae9a795c8a8	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 14:51:38.728+00	\N
165	a15b8a89-dfd0-4117-92a1-e60929e7d032	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 14:51:39.765+00	\N
166	d4c38fe2-5d8a-4bb8-ba09-441c163ad50f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 15:17:48.16+00	\N
167	c5096394-9782-4d77-8e72-c304c385f652	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 15:17:49.484+00	\N
168	4a6f5543-c38c-46c3-9c78-009d6b753447	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 15:37:20.013+00	\N
169	6bd78567-9a60-4f5e-9ce1-b35d00c9b276	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 15:37:21.136+00	\N
170	70c6dab1-e5b8-4fa7-8c16-3238fd40948b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 15:51:41.371+00	\N
171	e8147246-3a08-4b87-81ee-f3124b76693d	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 15:51:42.713+00	\N
172	2bbac87c-bb0c-43a7-a267-436f5723cab2	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 16:22:28.101+00	\N
173	daa1584e-967c-4444-8255-c53b54dd663e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 16:22:29.317+00	\N
174	4f8a72a0-41f3-4f88-89cf-d994ea90dab1	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 16:42:07.069+00	\N
175	42e78e85-b5ca-4a66-a390-1078ac6446ba	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 16:42:07.915+00	\N
176	53f75243-845d-4b90-ad9b-e6d24ef5d956	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 16:53:23.393+00	\N
177	1ead5bd7-aa72-431d-a552-d5c5d690a91b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 16:53:24.74+00	\N
178	3c1ca720-72cd-471b-8420-8f8ff9b2d7c1	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 17:15:39.264+00	\N
179	ed17f68f-77a1-44f2-8b5b-620e16c5da10	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 17:15:40.117+00	\N
180	626c8a68-316a-4543-88d6-0d821902e80d	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 17:37:40.901+00	\N
181	761b71bf-f4f7-4eb4-b203-4673363fb8cf	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 17:37:42.131+00	\N
182	e94a176a-692b-4e27-885a-da7ad32912fe	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 17:51:41.201+00	\N
183	0fb55071-2859-4142-ab13-60d3cb552712	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 17:51:42.211+00	\N
184	692bb25d-a270-4555-8c9a-190d2b36c483	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 18:26:35.585+00	\N
185	11898075-4ede-406a-b787-9cde88aac6a8	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 18:26:36.967+00	\N
186	1ea99751-cb77-467e-81a6-34f9dbf53160	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 18:44:38.267+00	\N
187	4826688a-2707-465d-9ced-5e1e69b5e4f4	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 18:44:39.564+00	\N
188	4a7961ab-bc49-4804-9e7d-da5ff66bbcef	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 18:55:38.831+00	\N
189	6d9b6ea2-7322-420b-a0bc-5b83dce59099	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 18:55:39.929+00	\N
190	caa73945-d91b-4bba-aa1a-b8a1cc6938c0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 19:15:08.323+00	\N
191	e3349755-bff5-4070-b8b4-ce5a65e45cef	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 19:15:09.201+00	\N
192	218ec805-93c1-43b3-baf3-c13172fe6aa0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 19:26:38.706+00	\N
193	86aed472-9e98-47ac-995b-4fb0592f5e08	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 19:26:39.609+00	\N
194	8cbe58f4-accb-4bb8-b6f9-26e797125147	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 19:38:52.772+00	\N
195	61961161-65a5-4dd1-a7b1-746908b03ee3	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 19:38:54.027+00	\N
196	6740afc5-159c-4232-ac52-ea6a722eb0ae	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 19:51:40.621+00	\N
197	06872e6d-4e73-4b19-99d4-7156778bf90e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 19:51:41.852+00	\N
198	031c96fd-6497-476a-99a0-9d340d14cf65	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 20:20:47.38+00	\N
199	adfe97d4-fd91-41f5-9034-c71c2dc94749	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 20:20:48.599+00	\N
200	e21bd8da-924f-4962-9ed8-75346502b3d4	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 20:39:04.25+00	\N
201	b78f39ec-75b3-44af-af78-921d5624c722	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 20:39:05.7+00	\N
202	6626da81-5585-4097-8600-6b9feea2cf54	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 20:51:38.908+00	\N
203	db2e94f9-c4f7-429f-9eb0-be8b99897bd7	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 20:51:40.319+00	\N
204	65c8ffed-bf27-4469-8247-1cea5155850b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 21:16:32.786+00	\N
205	4904129f-bea6-4f01-afa9-91739490ea22	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 21:16:34.176+00	\N
206	7c98c2ea-6af4-457a-b2f8-6bd6aff8a9da	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 21:37:19.97+00	\N
207	211d5797-46e0-4f47-9fdf-0ee37372ce12	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 21:37:20.881+00	\N
208	48402ab7-aa06-4944-a739-07443f12cfd6	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 21:51:38.911+00	\N
209	c29deb14-6bdf-4856-a1a8-3d7f33e804d9	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 21:51:40.184+00	\N
210	660ffeff-1cef-46c4-9015-0c97e9580c84	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 22:17:57.443+00	\N
211	ccd4d04e-f36e-44e2-b7a6-c393a5258118	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 22:17:58.764+00	\N
212	c142658b-906f-4955-8438-cf3d89bed732	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 22:39:01.115+00	\N
213	70b7fd9c-0f06-43db-8e9d-9756dcc3db87	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 22:39:02.324+00	\N
214	9b743752-861f-4603-9e75-32f07fc03dfa	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 22:51:46.243+00	\N
215	8956459d-2559-40bb-ad73-3a71dfcc1c9e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 22:51:47.67+00	\N
216	0c7f50a7-7b3c-426f-bee3-e87be937ebe0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 23:17:37.044+00	\N
217	600c4a3c-cccf-4f14-b57d-cc7e56caed5e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 23:17:37.931+00	\N
218	545e5023-c82d-43c1-9d3c-0f8c083eb19d	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 23:37:50.324+00	\N
219	4dd295b6-efac-42c3-87a8-a6c74767f1c4	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 23:37:52.273+00	\N
220	b9fc9a84-7e74-4506-8e6d-7b03da84626e	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-12 23:51:46.465+00	\N
221	7b7c4e19-8473-4760-9ec1-787f74348158	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-12 23:51:47.245+00	\N
222	9f005461-4d72-434e-9fd6-6a7b88bc0789	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 01:43:47.572+00	\N
223	cc4dc00a-a26a-4d9a-b03c-3ca405c55861	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 01:43:48.956+00	\N
224	da6fa0e1-113a-4ccf-8fa4-29e2445765da	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 03:01:58.48+00	\N
225	72787109-3d1e-45fa-adb7-ea056f6bfa0e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 03:01:59.935+00	\N
226	bba4773b-58ba-448f-92f4-838799a3714f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 03:04:46.398+00	\N
227	14680fc7-f630-4ad2-874f-31331da712d2	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 03:04:47.534+00	\N
228	0b2c4e93-3dea-4822-b2f7-52b3e7473e09	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 03:49:07.601+00	\N
229	435f2430-7fdd-46d6-a9b5-9ae88a20bedf	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 03:49:08.518+00	\N
230	4cdca170-a095-4ce8-b53b-f85ca6d62a96	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 04:25:04.209+00	\N
231	e8ae12dc-a3ff-4187-9347-0dd4b41eefe6	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 04:25:05.526+00	\N
232	dac62f16-6cdb-41d0-99be-be09bcfa350f	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 04:43:52.313+00	\N
233	396a7df0-b7bf-4841-b323-aef0f2b145d3	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 04:43:53.613+00	\N
234	20a8f7a7-fda9-4957-87a3-d078d036187b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 04:54:56.143+00	\N
235	b497ca6a-a253-4747-b790-9851a0e2e759	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 04:54:57.359+00	\N
236	1dd5e6ea-eb45-4ffd-ac1c-4b49c9fa673d	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 05:20:38.823+00	\N
237	b7e4a3e9-a4a9-46f0-9e7b-db0cb802d18c	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 05:20:39.897+00	\N
238	98b2eda9-b53c-499d-8c04-c114f5117869	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 05:41:53.044+00	\N
239	37008636-3660-4c89-bee6-0b2ae84b1c24	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 05:41:54.084+00	\N
240	f172615c-adfa-4b70-9000-d33b22271bcc	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 05:53:12.052+00	\N
241	c7a2356e-ff6c-418c-bb95-5b5872e4c84b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 05:53:13.29+00	\N
242	6595e9c9-46cc-4d59-ba1d-7fd683e0c3f7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 06:33:10.393+00	\N
243	ce96dd43-3fd6-4cc4-9301-39b898602132	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 06:33:11.831+00	\N
244	300e75b9-bdbc-4ef4-825c-9d1b5610c3a7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 06:56:36.407+00	\N
245	b645bad2-108a-4ab4-b770-c99b9f15f14c	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 06:56:37.141+00	\N
246	183cf8b5-cc79-46e2-864b-b23eb2ea0622	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 07:24:34.115+00	\N
247	32e7ea81-38f1-4a61-a88a-a9556ca4317f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 07:24:35.376+00	\N
248	4c01a2a4-dbc0-43a2-b5b6-bf111d02a547	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 07:39:52.067+00	\N
249	02c88144-8159-4d79-9d4e-cc0c298efd88	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 07:39:53.273+00	\N
250	29e10489-a779-4830-aae2-1dc473124a94	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 07:51:36.046+00	\N
251	7b1a48cc-002d-4406-8899-95e727f87852	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 07:51:37.131+00	\N
252	00120f59-25b0-484c-bb8d-daaac4de9dde	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 08:30:06.97+00	\N
253	c581a214-df5e-4811-8932-603a36e6e860	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 08:30:08.158+00	\N
254	96e6b63e-527d-43bc-a9e4-80d86f463ba9	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 08:52:17.828+00	\N
255	f310fba1-9ff9-4b2f-a9b6-d51950456094	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 08:52:18.748+00	\N
256	4f036d06-f283-464b-a92a-d568438804cb	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 09:25:51.39+00	\N
257	b5feaf15-a3f5-434c-826d-c84030295701	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 09:25:53.051+00	\N
258	be87048b-21b2-4dfa-913f-4baf414fc22a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 09:44:09.089+00	\N
259	9ed71f93-517c-4f82-afd5-70f8a852e9bd	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 09:44:10.23+00	\N
260	28a557b7-d7e8-4983-9e79-efe0fda1b050	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 09:55:14.567+00	\N
261	7f097c67-29ee-4539-a539-b7fde64d1fd3	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 09:55:15.756+00	\N
262	5633be8e-2245-45dc-a99d-efbef8f7d19a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 10:24:44.885+00	\N
263	5b007d02-4a39-496e-a0a6-508034eb803c	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 10:24:46.308+00	\N
264	eb0a04f6-11ca-40ec-930c-eb0e8ed401e8	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 10:45:01.697+00	\N
265	112f4f8f-4a84-4175-aae5-c0d902394af9	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 10:45:03.075+00	\N
266	db8022e1-3844-46e3-b0bf-0a223d7e5ab3	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 10:55:54.207+00	\N
267	37f5496d-902c-4d35-af83-6858d691d903	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 10:55:55.507+00	\N
268	1199b588-8dcf-4422-ac73-c2da5d85d356	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 11:19:00.41+00	\N
269	13625b3d-b18c-45c7-ab78-f3758eac4384	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 11:19:01.745+00	\N
270	682b89ec-3b70-455d-9574-a9b198e7b0c7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 11:38:16.434+00	\N
271	59dbc223-3e18-4bb8-9a2c-2e39f0850f6f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 11:38:17.468+00	\N
272	4caa6717-563e-4a76-8dd4-c7c807180520	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 11:51:26.707+00	\N
273	4c053116-85cd-41a1-bb11-1051dcf78dad	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 11:51:27.808+00	\N
274	49588a1b-6164-4357-af69-6071c71e4d5c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 12:43:04.355+00	\N
275	e6904041-b4d4-498f-984f-cae42894705b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 12:43:05.606+00	\N
276	3b24e92c-dc80-4e94-b227-9e9c7de89337	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 13:20:31.418+00	\N
277	f2c79d22-59c5-4159-9f45-4a169ffc7d83	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 13:20:32.672+00	\N
278	51f0abcc-6cd6-45e2-8039-8143f33417d4	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 13:46:48.62+00	\N
279	9fded079-1a35-48db-a6a0-d1b8079c3b13	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 13:46:49.935+00	\N
280	998a90d1-b9bc-401a-bfb2-b4a4357ebc6c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 14:21:50.859+00	\N
281	373dbd51-1285-4954-b609-2dcd1ac42c0f	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 14:21:52.083+00	\N
282	d9ae1986-ff6f-469d-981b-25a4d4387986	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 14:43:41.894+00	\N
283	206fe745-bb54-4291-9635-6588cbc219e5	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 14:43:42.664+00	\N
284	f75637fd-bec0-4324-9ee3-92ec31de45b7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 14:54:43.462+00	\N
285	d28840f3-944b-4b82-826c-6fd48bd6545a	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 14:54:45.071+00	\N
286	463de3cf-52c5-4d35-b179-1c6925da5636	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 15:21:12.018+00	\N
287	48cc46ef-040d-4398-8e4e-3999d408bc8d	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 15:21:13.372+00	\N
288	f9034ae1-a71a-45f7-964e-ab473934b97a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 15:40:42.42+00	\N
289	9825c827-9f21-4b6a-8afd-f1011fb96fa0	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 15:40:43.501+00	\N
290	37551ee6-ec07-4ec0-aa2b-97d93b9306a0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 15:51:57.911+00	\N
291	fc8e4dfe-8f82-40b5-8d54-2abda0b69bbb	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 15:51:59.015+00	\N
292	4c1d0cb9-93ae-4bb6-aa38-a198bb5c7a6c	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 16:26:24.514+00	\N
293	905136c7-4867-424c-b925-2decbeadd7ab	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 16:26:25.946+00	\N
294	ae252ade-d97e-4f58-b430-df14fb2e5ede	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 16:46:46.956+00	\N
295	d2476ca2-d23c-497d-b5fa-e4eb17366bb6	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 16:46:48.182+00	\N
296	eed37ef9-5a44-47ea-9499-78015228f130	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 17:17:49.216+00	\N
297	59d99449-572c-4851-83aa-1fa0b0150fd0	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 17:17:50.56+00	\N
298	c46b3693-60d1-4ae4-bf9e-a639457873f7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 17:39:41.837+00	\N
299	d7731da4-80f6-451e-9c02-08d6e6d72d67	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 17:39:42.913+00	\N
300	31237ccd-0214-40bf-8157-6a16e06c466b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 17:51:50.626+00	\N
301	94790fb1-ac60-4669-aeb4-330422fc388d	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 17:51:51.757+00	\N
302	242dd4a7-28cc-4e78-99a5-25bd9e073469	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 18:28:54.74+00	\N
303	8782a058-7241-41fc-b8ad-f07085e37db2	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 18:28:56.082+00	\N
304	03ca7c50-ef25-4569-9e61-ac00e93024f7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 18:49:01.124+00	\N
305	cef38e30-1a54-49e2-8152-34f153399c34	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 18:49:02.475+00	\N
306	d481eb3c-9fda-44b7-9bc0-ed1e48b32199	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 19:15:43.429+00	\N
307	5cf66a74-8ed8-4858-a8ed-8910822340ee	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 19:15:45.153+00	\N
308	fb52cac1-e3b2-4e46-88b9-5d36a3d912b0	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 19:37:54.952+00	\N
309	e5b1be67-083f-4902-8a22-bfbeb900904b	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 19:37:56.81+00	\N
310	358a2a0f-061a-4892-85fc-b48f5f1b1eef	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 19:51:39.496+00	\N
311	a28e4588-a862-4c46-96e7-426cd248cd24	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 19:51:40.567+00	\N
312	38935760-78ee-4f27-8e3d-b247ad6557f9	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 20:22:47.245+00	\N
313	2cf39628-c7d7-4cfb-a3c5-3469c1bc573e	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 20:22:48.328+00	\N
314	62cc7e2c-7657-49c7-a057-69ce6a54bfb7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 20:40:41.28+00	\N
315	caacc77b-6259-4647-af69-e08b00942351	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 20:40:43.054+00	\N
316	427fe6b8-419b-4937-af88-beb09eb4a7b2	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 20:52:10.009+00	\N
317	4b34b276-f87d-4ef9-85d4-638688147a39	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 20:52:11.199+00	\N
318	c7c84be5-eb6b-4a34-9cf4-044c67adcf34	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 21:18:17.369+00	\N
319	6ec4476d-595f-453e-9aa0-3e5ea67734af	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 21:18:18.92+00	\N
320	aa467496-f153-4510-b05f-a98f158393be	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 21:36:19.265+00	\N
321	d98d3bcf-9be7-4cf2-aa6f-b16abfb57a04	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 21:36:20.602+00	\N
322	fa0d8e4d-029a-46bd-84b9-fcc90eefad48	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 21:51:44.702+00	\N
323	a178531d-5ab9-4ee1-bbe0-22e8e68fb553	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 21:51:45.976+00	\N
324	0421a3ff-dd8e-41a8-9dd0-18828b4948c7	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 22:18:30.931+00	\N
325	cf8b08b5-c5f2-4cb4-8be4-16386c7ca2a1	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 22:18:31.809+00	\N
326	946c03e8-6f5c-4cb7-8c8b-ea2f1c580d34	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 22:39:51.737+00	\N
327	2995b9ea-6626-448e-bae9-0b95cf89a5d7	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 22:39:53.586+00	\N
328	19205e47-e856-44f2-934d-6b3a1e58e6ba	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 22:51:49.615+00	\N
329	59d2e6c2-21b0-4c77-9ad8-11aaf2ac4151	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 22:51:50.829+00	\N
330	bcbb2185-2395-42a0-8ecf-4d44c45965ee	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 23:17:44.957+00	\N
331	5c9b0598-203a-4cdc-ae6c-a9d8b0350586	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 23:17:46.363+00	\N
332	ddddbe01-de24-4c39-b759-20b2d847040a	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 23:37:56.934+00	\N
333	2f8ddea8-be3d-4f60-8b08-0962ab121e75	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 23:37:58.156+00	\N
334	04c9748c-96f9-4faa-a650-dcd57924cb0b	\N	\N	1	creator	10000.00	USD	queued	\N	2025-10-13 23:51:42.722+00	\N
335	dbb784b0-d7bd-4461-95f2-825771dbf295	\N	\N	4	creator	10000.00	USD	queued	\N	2025-10-13 23:51:44.013+00	\N
338	8dc9fd03-ea6c-4e9e-bdef-aa5d5b43ed7b	\N	1db240db-c452-40c1-9df5-81f523f86bf7	\N	ip_holder	300.00	AUD	queued	\N	2025-10-21 02:44:41.88457+00	\N
339	aa1179b9-9685-4a46-961c-35950ac0480b	\N	29f15f66-7141-469a-bcb5-ce592081f043	\N	creator	400.00	AUD	queued	\N	2025-10-21 02:44:41.88457+00	\N
340	46867891-08ae-476b-948b-922c3dd3d7bf	\N	238e2322-8177-4838-84af-2e07e68c7ef3	\N	referrer	200.00	AUD	queued	\N	2025-10-21 02:44:41.88457+00	\N
341	80be8523-e35b-497e-bb02-c82f527b4beb	\N	aa932b32-7fbe-4765-a8c8-cb277f35027f	\N	ip_holder	250.00	AUD	queued	\N	2025-10-21 03:01:25.48316+00	\N
342	9a5b63dc-b3e8-477c-ba2c-b5692ee46060	\N	4e4a8571-cb4c-4c84-85dd-f6e86bdbf7bb	\N	creator	625.00	AUD	queued	\N	2025-10-21 03:01:25.48316+00	\N
343	f2b6673e-cd33-4d9b-b281-1e41a457ab28	\N	00d0a1df-8883-4683-b9fd-e1e31b2e93af	\N	referrer	125.00	AUD	queued	\N	2025-10-21 03:01:25.48316+00	\N
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sales (sale_id, offer_id, offer_name, gross_amount, sale_currency, vault_id, creator_id, ip_holder, referrer_id, override_json, sale_date, status, cadence, term_months, billing_day, stripe_invoice_id, stripe_subscription_id) FROM stdin;
4	\N	Continuity Ops Seat	2000.00	AUD	VLT-002	creator-001	Vault IP LLC	referrer-001	{"ip": 0.15, "creator": 0.20, "referrer": 0.10}	2025-10-21 02:44:41.88457+00	queued	monthly	12	15	\N	\N
5	\N	Premium Automation Seat	2500.00	AUD	VLT-003	creator-002	Vault IP LLC	referrer-002	{"ip": 0.10, "creator": 0.25, "referrer": 0.05}	2025-10-21 03:01:25.48316+00	queued	monthly	36	15	inv_test_001	sub_test_001
\.


--
-- Data for Name: stripe_sync_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stripe_sync_log (id, sale_id, stripe_object, object_id, payload, status, created_at) FROM stdin;
1	5	invoice	inv_test_001	{}	queued	2025-10-21 03:01:25.48316+00
\.


--
-- Name: payouts_v2_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payouts_v2_id_seq', 343, true);


--
-- Name: sales_sale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sales_sale_id_seq', 5, true);


--
-- Name: stripe_sync_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stripe_sync_log_id_seq', 1, true);


--
-- PostgreSQL database dump complete
--

\unrestrict 3wGkrIj8dwhu4HTgpDnEE7QpARYgBU4ZsWY9Kl0hlS1SRpI7pGNHDnhlRC67eYh

