// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

// use a struct to make passing params during recursion easier
typedef struct
{
    const char    *str_p;           // pointer to string to be searched
    long    str_len;                // length of same
    const char    *abbrev_p;        // pointer to search string (abbreviation)
    long    abbrev_len;             // length of same
    double  max_score_per_char;
    int     dot_file;               // boolean: true if str is a dot-file
    int     always_show_dot_files;  // boolean
    int     never_show_dot_files;   // boolean
} matchinfo_t;

static double recursive_match(matchinfo_t *m,  // sharable meta-data
                       long str_idx,           // where in the path string to start
                       long abbrev_idx,        // where in the search string to start
                       long last_idx,          // location of last matched character
                       double score,           // cumulative score so far
                       long* pos)              // the position of matched char
{
    double seen_score = 0;      // remember best score seen via recursion
    int dot_file_match = 0;     // true if abbrev matches a dot-file
    int dot_search = 0;         // true if searching for a dot

    long* seen_pos = pos ? (long*)calloc(m->abbrev_len-abbrev_idx, sizeof(long)) : NULL;
    long seen_idx = 0;

    long i = 0;
    long j = 0;

    for (i = abbrev_idx; i < m->abbrev_len; i++)
    {
        int found = 0;
        char c = m->abbrev_p[i];
        if (c == '.')
            dot_search = 1;
        for (j = str_idx; j < m->str_len; j++, str_idx++)
        {
            char d = m->str_p[j];
            if (d == '.')
            {
                if (j == 0 || m->str_p[j - 1] == '/'
#ifdef _WIN32
                    || m->str_p[i - 1] == '\\'
#endif
                )
                {
                    m->dot_file = 1;        // this is a dot-file
                    if (dot_search)         // and we are searching for a dot
                        dot_file_match = 1; // so this must be a match
                }
            }
            else if (d >= 'A' && d <= 'Z')
                d += 'a' - 'A'; // add 32 to downcase

            if (c >= 'A' && c <= 'Z')
                c += 'a' - 'A'; // add 32 to downcase

            if (c == d)
            {
                double score_for_char = m->max_score_per_char;
                long distance = j - last_idx;

                found = 1;
                dot_search = 0;

                // calculate score
                if (distance > 1)
                {
                    double factor = 1.0;
                    char last = m->str_p[j - 1];
                    char curr = m->str_p[j]; // case matters, so get again
                    if (last == '/'
#ifdef _WIN32
                        || last == '\\'
#endif
                    )
                        factor = 0.9;
                    else if (last == '-' ||
                            last == '_' ||
                            last == ' ' ||
                            (last >= '0' && last <= '9'))
                        factor = 0.8;
                    else if (last >= 'a' && last <= 'z' &&
                            curr >= 'A' && curr <= 'Z')
                        factor = 0.8;
                    else if (last == '.')
                        factor = 0.7;
                    else if (last_idx != -1)
                        // if no "special" chars behind char, factor diminishes
                        // as distance from last matched char increases
                        factor = (1.0 / distance) * 0.75;

                    if (last_idx == -1)
                    {
                        factor *=  1.0 * distance / m->str_len;
                    }

                    score_for_char *= factor;
                }
                else if (last_idx == -1)
                {
                    score_for_char /= m->str_len;
                }

                if (++j < m->str_len)
                {
                    // bump cursor one char to the right and
                    // use recursion to try and find a better match
                    double sub_score = recursive_match(m, j, i, last_idx, score, pos);
                    if (sub_score > seen_score)
                    {
                        seen_score = sub_score;
                        seen_idx = i;
                        if (seen_pos)
                            memcpy(seen_pos + i - abbrev_idx, pos + i, (m->abbrev_len - i) * sizeof(long));
                    }
                }

                if (pos)
                {
                    pos[i] = str_idx;
                }

                score += score_for_char;
                last_idx = str_idx++;

                break;
            }
        }
        if (!found)
        {
            if (seen_pos)
                free(seen_pos);
            return 0.0;
        }
    }
    if (m->dot_file)
    {
        if (m->never_show_dot_files ||
            (!dot_file_match && !m->always_show_dot_files))
        {
            if (seen_pos)
                free(seen_pos);
            return 0.0;
        }
    }

    if (score > seen_score)
        return score;

    if (seen_pos)
    {
        if (pos)
            memcpy(pos + seen_idx, seen_pos + seen_idx - abbrev_idx, (m->abbrev_len - seen_idx) * sizeof(long));
        free(seen_pos);
    }

    return seen_score;
}

typedef struct
{
    int     always_show_dot_files;  // boolean
    int     never_show_dot_files;   // boolean
} option_t;

#ifdef _WIN32
__declspec(dllexport)
#endif
double get_score(const char* string, const char* abbrev, const option_t* opt, long* pos)
{
    double score = 1.0;
    matchinfo_t m;

    m.str_p                 = string;
    m.str_len               = strlen(string);
    m.abbrev_p              = abbrev;
    m.abbrev_len            = strlen(abbrev);

    /* m.max_score_per_char    = (1.0 / m.str_len + 1.0 / m.abbrev_len) / 2; */
    m.max_score_per_char    = 1.0 / m.abbrev_len;
    m.dot_file              = 0;
    m.always_show_dot_files = opt->always_show_dot_files;
    m.never_show_dot_files  = opt->never_show_dot_files;

    // calculate score
    if (m.abbrev_len == 0) // special case for zero-length search string
    {
        // filter out dot files
        if (!m.always_show_dot_files)
        {
            long i = 0;
            for (i = 0; i < m.str_len; ++i)
            {
                char c = m.str_p[i];
                if (c == '.' && (i == 0 || m.str_p[i - 1] == '/'
#ifdef _WIN32
                                 || m.str_p[i - 1] == '\\'
#endif
                                )
                )
                {
                    score = 0.0;
                    break;
                }
            }
        }
    }
    else if (m.str_len == 0)
    {
        score = 0.0;
    }
    else // normal case
    {
        score = recursive_match(&m, 0, 0, -1, 0.0, pos);
    }

    return score;
}

