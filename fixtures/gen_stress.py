import json
from pathlib import Path

def gen_stress_fixture(num_sentences=10000):
    sentences = []
    links = []
    themes = []
    issues = []

    # Create themes (1 theme per 1000 sentences)
    num_themes = num_sentences // 1000
    for t in range(num_themes):
        theme_id = f"t{t+1}"
        theme_sentence_ids = []
        for i in range(1000):
            sid = f"s{t*1000 + i + 1}"
            sentence = {
                "id": sid,
                "text": f"Sentence {sid}: dummy legal text goes here.",
                "labels": ["StressTest"],
                "links": [],
                "status": "disputed" if i % 3 == 0 else "agreed",
                "themeId": theme_id,
            }
            sentences.append(sentence)
            theme_sentence_ids.append(sid)

        themes.append({
            "id": theme_id,
            "name": f"Theme {t+1}",
            "sentenceIds": theme_sentence_ids,
        })

    # Create dummy links (one every ~100 sentences)
    for i in range(1, num_sentences, 100):
        if i + 1 <= num_sentences:
            links.append({
                "id": f"l{i}",
                "sourceSentenceId": f"s{i}",
                "targetSentenceId": f"s{i+1}",
                "type": "claim-response",
            })

    # One giant issue containing all sentences
    issues.append({
        "id": "i1",
        "name": "Stress Test Issue",
        "sentenceIds": [f"s{i+1}" for i in range(num_sentences)],
    })

    return {
        "sentences": sentences,
        "links": links,
        "themes": themes,
        "issues": issues,
    }

if __name__ == "__main__":
    out_path = Path(__file__).parent / "stress-10k.json"
    data = gen_stress_fixture()
    with open(out_path, "w") as f:
        json.dump(data, f, indent=2)
    print(f"Generated {out_path}")
